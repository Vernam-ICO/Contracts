pragma solidity ^0.4.20;

library SafeMath {

	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		assert(c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		// assert(b > 0); // Solidity automatically throws when dividing by 0
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
}

contract Ownable {
	address public owner;
	address public controller;
	
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
	function Ownable() public {
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}
	
	modifier onlyController() {
		require(msg.sender == controller);
		_;
	}

	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}
	
	function setController(address _controllerAddress) public onlyOwner {
		controller = _controllerAddress;
	}
}

contract VernamCrowdSale is Ownable {
	using SafeMath for uint256;
		
	address public benecifiary;
	
	bool public isThreeHotHoursActive;
	bool isInPrivatePreSale;
	
	uint public startTime;
	uint public totalSoldTokens;
	uint constant FIFTEEN_ETHERS = 15 ether;
	uint constant minimumContribution = 100 finney;
	uint constant maximumContribution = 500 ether;
	uint public totalContributedWei;
	
	uint constant public privatePreSaleDuration = 30 days;
	uint constant public privatePreSalePriceOfTokenInWei = 100000000000000 wei; //1 eth == 10 000
	uint constant public privatePreSaleTokensCap = 100000; // 100 000 tokens
	// uint constant public privatePreSaleCapInWei = privatePreSalePriceOfTokenInWei.mul(privatePreSaleTokensCap);
	
	uint public privatePreSaleEnd;

	uint constant public threeHotHoursDuration = 3 hours;
	uint constant public threeHotHoursPriceOfTokenInWei = 100000000000000 wei; //1 eth == 10 000
	uint constant public threeHotHoursTokensCap = 100000; // 100 000 tokens
	
	uint public threeHotHoursCapInWei = threeHotHoursPriceOfTokenInWei.mul(threeHotHoursTokensCap);
	uint public threeHotHoursEnd;
	
	uint constant public firstStageDuration = 24 hours;
	uint constant public firstStagePriceOfTokenInWei = 200000000000000 wei;    //1 eth == 5000
	uint constant public firstStageTokensCap = 100000; // 100 000 tokens  //maybe not constant because we must recalculate if previous have remainig

    uint public firstStageCapInWei = firstStagePriceOfTokenInWei.mul(firstStageTokensCap);
	uint public firstStageEnd;
	
	uint constant public secondStageDuration = 6 days;
	uint constant public secondStagePriceOfTokenInWei = 400000000000000 wei;    //1 eth == 2500
	uint constant public secondStageTokensCap = 100000; // 100 000 tokens       //maybe not constant because we must recalculate if previous have remainig
    
    uint public secondStageCapInWei = secondStagePriceOfTokenInWei.mul(secondStageTokensCap);
	uint public secondStageEnd;
	
	uint constant public thirdStageDuration = 26 days;
	uint constant public thirdStagePriceOfTokenInWei = 600000000000000 wei;          //1 eth == 1500
	
	uint constant public thirdStageDiscountPriceOfTokenInWei = 800000000000000 wei;  //1 eth == 1250
	
	uint constant public thirdStageTokens = 100000; // 100 000 tokens //maybe not constant because we must recalculate if previous have remainig
	uint public thirdStageEnd;
	
	uint public thirdStageDiscountCapInWei = thirdStageDiscountPriceOfTokenInWei.mul(thirdStageTokens);
	uint public thirdStageCapInWei = thirdStagePriceOfTokenInWei.mul(thirdStageTokens);
	
	uint constant public TOKENS_SOFT_CAP = 40000000000000000000000000;  // 40 000 000 with 18 decimals
	uint constant public TOKENS_HARD_CAP = 500000000000000000000000000; // 500 000 000 with 18 decimals
	
	// Constants for Realase Three Hot Hours
	uint constant public LOCK_TOKENS_DURATION = 30 days;
	uint public FIRST_MONTH_END ;
	uint public SECOND_MONTH_END ;
	uint public THIRD_MONTH_END ;
	uint public FOURTH_MONTH_END ;
	uint public FIFTH_MONTH_END ;

	mapping(address => uint) public contributedInWei;
	mapping(address => uint) public boughtTokens;
	mapping(address => uint) public threeHotHoursTokens;
	mapping(address => mapping(uint => uint)) public getTokensBalance;
	mapping(address => mapping(uint => bool)) public isTokensTaken;
	mapping(address => bool) public isCalculated;
	
	// VernamCrowdsaleToken public vernamCrowdsaleToken;
	// VernamWhiteListDeposit public vernamWhiteListDeposit;
	
	// Modifiers
    modifier softCapNotReached() {
        require(totalSoldTokens < TOKENS_SOFT_CAP);
        _;    
    }
    
    modifier afterCrowdsale() {
        require(block.timestamp > thirdStageEnd);
        _;
    }
    
    modifier isAfterThreeHotHours {
	    require(block.timestamp > threeHotHoursEnd);
	    _;
	}
	
    // Events
    event PrivatePreSaleActivated(uint startTime, uint endTime);
    event CrowdsaleActivated(uint startTime, uint endTime);
    event TokensBought(address participant, uint weiAmount, uint tokensAmount);
    
	function VernamCrowdSale(address _vernamWhiteListDepositAddress, address _controllerAddress) public {
		benecifiary = 0xca35b7d915458ef540ade6068dfe2f44e8fa733c;
		// vernamCrowdsaleToken = VernamCrowdsaleToken(vernamCrowdsaleTokenAddress);
		// vernamWhiteListDeposit = VernamWhiteListDeposit(_vernamWhiteListDepositAddress);
		
		startTime = block.timestamp;
		privatePreSaleEnd = startTime.add(privatePreSaleDuration);
		isInPrivatePreSale = true;
		
		setController(_controllerAddress);
		
		emit PrivatePreSaleActivated(startTime, privatePreSaleEnd);
	}
	
	function activateCrowdSale() public onlyOwner {
		require(isInPrivatePreSale == true);
	    isThreeHotHoursActive = true;
		startTime = block.timestamp;
		threeHotHoursEnd = startTime.add(threeHotHoursDuration);
		firstStageEnd = threeHotHoursEnd.add(firstStageDuration);
		secondStageEnd = firstStageEnd.add(secondStageDuration);
		thirdStageEnd = secondStageEnd.add(thirdStageDuration);
	
	    isInPrivatePreSale = false;
	    
		timeLock();

	    emit CrowdsaleActivated(startTime, thirdStageEnd);
	}
	
	function timeLock() internal {
		FIRST_MONTH_END = (startTime.add(LOCK_TOKENS_DURATION)).add(threeHotHoursDuration);
		SECOND_MONTH_END = FIRST_MONTH_END.add(LOCK_TOKENS_DURATION);
		THIRD_MONTH_END = SECOND_MONTH_END.add(LOCK_TOKENS_DURATION);
		FOURTH_MONTH_END = THIRD_MONTH_END.add(LOCK_TOKENS_DURATION);
		FIFTH_MONTH_END = FOURTH_MONTH_END.add(LOCK_TOKENS_DURATION);
	}
	
	function() public payable {
		buyTokens(msg.sender,msg.value);
	}
	
	function buyTokens(address _participant, uint _weiAmount) public payable returns(bool) {
		require(_weiAmount >= minimumContribution); // if value is smaller than most expensive stage price will count 0 tokens 
		require(_weiAmount <= maximumContribution);
		
		validatePurchase(_participant, _weiAmount);
		
		if (isInPrivatePreSale == true) {
		    privatePresaleBuy(_participant, _weiAmount);  
		    return true;
		}
		
		uint currentLevelTokens;
		uint nextLevelTokens;
		(currentLevelTokens, nextLevelTokens) = calculateAndCreateTokens(_weiAmount);
		
		uint tokensAmount = currentLevelTokens.add(nextLevelTokens);
		require(totalSoldTokens.add(tokensAmount) <= TOKENS_HARD_CAP);
		
		// transfer ethers here
		//vernamCrowdsaleToken.mintToken(_participant, tokens);        
		
		contributedInWei[_participant] = contributedInWei[_participant].add(_weiAmount);
		
		if(isThreeHotHoursActive == true) {
			threeHotHoursTokens[_participant] = threeHotHoursTokens[_participant].add(currentLevelTokens);
			boughtTokens[_participant] = boughtTokens[_participant].add(nextLevelTokens);
			isCalculated[_participant] = false;
		} else {	
			boughtTokens[_participant] = boughtTokens[_participant].add(tokensAmount);
		}
		
		totalSoldTokens = totalSoldTokens.add(tokensAmount);
		totalContributedWei = totalContributedWei.add(_weiAmount);
		
		emit TokensBought(_participant, _weiAmount, tokensAmount);
		
		return true;
	}
	
	function privatePresaleBuy(address _participant, uint _weiAmount) internal {
		require(isInPrivatePreSale == true);
		require(totalSoldTokens < privatePreSaleTokensCap);
        require(block.timestamp <= privatePreSaleEnd);
        
		uint tokens = _weiAmount.div(privatePreSalePriceOfTokenInWei);
		boughtTokens[_participant] = boughtTokens[_participant].add(tokens);
		
		totalSoldTokens = totalSoldTokens.add(tokens);
		
		emit TokensBought(_participant, _weiAmount, tokens);
	}
	
	function calculateAndCreateTokens(uint weiAmount) public returns (uint _currentLevelTokensAmount, uint _nextLevelTokensAmount) {

		if(block.timestamp < threeHotHoursEnd && totalSoldTokens < threeHotHoursTokensCap) {
		    (_currentLevelTokensAmount, _nextLevelTokensAmount) = tokensCalculator(weiAmount, threeHotHoursPriceOfTokenInWei, firstStagePriceOfTokenInWei, threeHotHoursCapInWei);
			
			return (_currentLevelTokensAmount, _nextLevelTokensAmount);
		}
		
		if(block.timestamp < firstStageEnd || totalSoldTokens < firstStageTokensCap) {
		    (_currentLevelTokensAmount, _nextLevelTokensAmount) = tokensCalculator(weiAmount, firstStagePriceOfTokenInWei, secondStagePriceOfTokenInWei, firstStageCapInWei);
			
			isThreeHotHoursActive = false;
			
			return (_currentLevelTokensAmount, _nextLevelTokensAmount);
		}
		
		if(block.timestamp < secondStageEnd || totalSoldTokens < secondStageTokensCap) {
			(_currentLevelTokensAmount, _nextLevelTokensAmount) = tokensCalculator(weiAmount, secondStagePriceOfTokenInWei, thirdStagePriceOfTokenInWei, secondStageCapInWei);
			return (_currentLevelTokensAmount, _nextLevelTokensAmount);
		}
		
		if(block.timestamp < thirdStageEnd || totalSoldTokens < thirdStageTokens && weiAmount > FIFTEEN_ETHERS) {
			(_currentLevelTokensAmount, _nextLevelTokensAmount) = tokensCalculator(weiAmount, thirdStageDiscountPriceOfTokenInWei, thirdStageDiscountPriceOfTokenInWei, thirdStageDiscountCapInWei);
			return (_currentLevelTokensAmount, _nextLevelTokensAmount);
		}
		
		if(block.timestamp < thirdStageEnd || totalSoldTokens < thirdStageTokens){
			(_currentLevelTokensAmount, _nextLevelTokensAmount) = tokensCalculator(weiAmount, thirdStagePriceOfTokenInWei, thirdStagePriceOfTokenInWei, thirdStageCapInWei);
			return (_currentLevelTokensAmount, _nextLevelTokensAmount);
		}
		
		revert();
	}
	
	function tokensCalculator(uint weiAmount, uint currentLevelPrice, uint nextLevelPrice, uint currentLevelCap) internal view returns (uint256, uint256){
	    uint currentAmountInWei = 0;
		uint remainingAmountInWei = 0;
		uint currentLevelTokensAmount = 0;
		uint nextLevelTokensAmount = 0;
		
		if(weiAmount.add(totalContributedWei) > currentLevelCap) {
		    remainingAmountInWei = (weiAmount.add(totalContributedWei)).sub(currentLevelCap);
		    currentAmountInWei = weiAmount.sub(remainingAmountInWei);
            
            currentLevelTokensAmount = currentAmountInWei.div(currentLevelPrice);
            nextLevelTokensAmount = remainingAmountInWei.div(nextLevelPrice); 
	    } else {
	        currentLevelTokensAmount = weiAmount.div(currentLevelPrice);
			nextLevelTokensAmount = 0;
	    }

		return (currentLevelTokensAmount, nextLevelTokensAmount);
	}
	
	function realaseThreeHotHourTokens(address _participant) public onlyController isAfterThreeHotHours returns(bool) { 
		uint _amount = unlockTokensAmount(_participant);
		
		if(isCalculated[_participant] == false) {
		    calculateTokensForMonth(_participant);
		    isCalculated[_participant] = true;
		}
		
		threeHotHoursTokens[_participant] = threeHotHoursTokens[_participant].sub(_amount);
		boughtTokens[_participant] = boughtTokens[_participant].add(_amount);
		
		return true;
	}
	
	function calculateTokensForMonth(address _participant) internal {
	    uint maxBalance = threeHotHoursTokens[_participant];
	    uint percentage = 10;
	    for(uint month = 0; month < 6; month++) {
	        if(month == 3 || month == 5) {
	            percentage += 10;
	        }
	        getTokensBalance[_participant][month] = maxBalance / percentage;
	        isTokensTaken[_participant][month] = false; // This is not needed we can check if there is balance in getTokensBalance when unlock tokens 
	    }
	}
	
	function unlockTokensAmount(address _participant) internal returns (uint) {
		require(threeHotHoursTokens[_participant] > 0);
		
        if(block.timestamp < FIRST_MONTH_END && isTokensTaken[_participant][0] == false) {
            return getTokens(_participant, 1); // First month
        } 
        
        if(((block.timestamp >= FIRST_MONTH_END) && (block.timestamp < SECOND_MONTH_END)) 
            && isTokensTaken[_participant][1] == false) 
        {
            return getTokens(_participant, 2); // Second month
        } 
        
        if(((block.timestamp >= SECOND_MONTH_END) && (block.timestamp < THIRD_MONTH_END)) 
            && isTokensTaken[_participant][2] == false) {
            return getTokens(_participant, 3); // Third month
        } 
        
        if(((block.timestamp >= THIRD_MONTH_END) && (block.timestamp < FOURTH_MONTH_END)) 
            && isTokensTaken[_participant][3] == false) {
            return getTokens(_participant, 4); // Forth month
        } 
        
        if(((block.timestamp >= FOURTH_MONTH_END) && (block.timestamp < FIFTH_MONTH_END)) 
            && isTokensTaken[_participant][4] == false) {
            return getTokens(_participant, 5); // Fifth month
        } 
        
        if((block.timestamp >= FIFTH_MONTH_END) 
            && isTokensTaken[_participant][5] == false) {
            return getTokens(_participant, 6); // Last month
        }
    }
    
    function getTokens(address _participant, uint _period) internal returns(uint) {
        uint tokens = 0;
        for(uint month = 0; month < _period; month++) {
            if(isTokensTaken[_participant][month] == false) {
                isTokensTaken[_participant][month] == true;
                
                tokens += getTokensBalance[_participant][month];
                getTokensBalance[_participant][month] = 0;
            }
        }
        
        return tokens;
    }
	
	function validatePurchase(address _participant, uint _weiAmount) pure internal {
        require(_participant != address(0));
        require(_weiAmount != 0);
    }
    
    function getContributedAmountInWei(address _participant) public view returns (uint) {
        return contributedInWei[_participant];
    }
    
    function setContributedAmountInWei(address _participant) public softCapNotReached afterCrowdsale onlyController returns (bool) {
        contributedInWei[_participant] = 0;
        
        return true;
    }
}

contract Controller {
    
    VernamCrowdSale vernamCrowdSale;
    
    event Refunded(address _to, uint amountInWei);
    
    function Controller(address _crowdsaleAddress) public {
        vernamCrowdSale = VernamCrowdSale(_crowdsaleAddress);
    }
    
    function safeWithdraw() public {
        refund(msg.sender);
    }
    
    function refund(address _to) internal {
        uint amountInWei = vernamCrowdSale.getContributedAmountInWei(_to);
        
        require(amountInWei > 0);
        
        vernamCrowdSale.setContributedAmountInWei(_to);
        _to.transfer(amountInWei);
        
        emit Refunded(_to, amountInWei);
    }
    
    function realaseThreeHotHourTokens() public {
        vernamCrowdSale.realaseThreeHotHourTokens(msg.sender);
    }
}
