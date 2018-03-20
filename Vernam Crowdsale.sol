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
	uint public totalContributedWei;
	
	uint constant public privatePreSaleDuration = 3 hours;
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
	
	uint constant public thirdStageDiscountPriceOfTokenInWei = 800000000000000 wei; //1 eth == 1250
	
	uint constant public thirdStageTokens = 100000; // 100 000 tokens //maybe not constant because we must recalculate if previous have remainig
	uint public thirdStageEnd;
	
	uint public thirdStageDiscountCapInWei = thirdStageDiscountPriceOfTokenInWei.mul(thirdStageTokens);
	uint public thirdStageCapInWei = thirdStagePriceOfTokenInWei.mul(thirdStageTokens);
	
	uint constant public TokensHardCap = 500000000000000000000000000;  //500 000 000 with 18 decimals
	
	// Constants for Realase Three Hot Hours
	uint constant public LOCK_TOKENS_DURATION = 30 days;
	uint constant public FIRST_MONTH = LOCK_TOKENS_DURATION;
	uint constant public SECOND_MONTH = LOCK_TOKENS_DURATION + FIRST_MONTH;
	uint constant public THIRD_MONTH = LOCK_TOKENS_DURATION + SECOND_MONTH;
	uint constant public FOURTH_MONTH = LOCK_TOKENS_DURATION + THIRD_MONTH;
	uint constant public FIFTH_MONTH = LOCK_TOKENS_DURATION + FOURTH_MONTH;
	// uint constant public SIXTH_MONTH = LOCK_TOKENS_DURATION + FIFTH_MONTH;
	
	mapping(address => uint) whenBought;
	mapping(address => uint) public contributedInWei;
	mapping(address => uint) public boughtTokens;
	mapping(address => uint) public threeHotHoursTokens;
	// mapping(address => uint) public threeHotHoursTokensMaxBalance;
	// mapping(address => uint) percentage;
	
	
	// VernamCrowdsaleToken public vernamCrowdsaleToken;
    
    // Events
    event PrivatePreSaleActivated(uint startTime, uint endTime);
    event CrowdsaleActivated(uint startTime, uint endTime);
    event TokensBought(address participant, uint weiAmount, uint tokensAmount);
    
	function VernamCrowdSale() public {
		benecifiary = 0xca35b7d915458ef540ade6068dfe2f44e8fa733c;
		// vernamCrowdsaleToken = VernamCrowdsaleToken(vernamCrowdsaleTokenAddress);
		
		startTime = block.timestamp;
		privatePreSaleEnd = startTime.add(privatePreSaleDuration);
		isInPrivatePreSale = true;
		
		emit PrivatePreSaleActivated(startTime, privatePreSaleEnd);
	}
	
	function activateCrowdSale() public onlyOwner {
		require(isInPrivatePreSale = true);
	    
	    isThreeHotHoursActive = true;
		startTime = block.timestamp;
		// privatePreSaleEnd = startTime.add(privatePreSaleDuration);
		threeHotHoursEnd = startTime.add(threeHotHoursDuration);
		firstStageEnd = threeHotHoursEnd.add(firstStageDuration);
		secondStageEnd = firstStageEnd.add(secondStageDuration);
		thirdStageEnd = secondStageEnd.add(thirdStageDuration);
	
	    isInPrivatePreSale = false;
	    
	    emit CrowdsaleActivated(startTime, thirdStageEnd);
	}
	
	function() public payable {
		buyTokens(msg.sender,msg.value);
	}
	
	function buyTokens(address _participant, uint _weiAmount) public payable returns(bool) {
		require(_weiAmount >= minimumContribution); // if value is smaller than most expensive stage price will count 0 tokens 
		
		validatePurchase(_participant, _weiAmount);
		
		if (isInPrivatePreSale = true) {
		    privatePresaleBuy(_participant, _weiAmount);  
		    return true;
		}
		
		uint currentLevelTokens;
		uint nextLevelTokens;
		(currentLevelTokens, nextLevelTokens) = calculateAndCreateTokens(_weiAmount);
		
		require(totalSoldTokens.add(currentLevelTokens.add(nextLevelTokens)) <= TokensHardCap);
		
		// transfer ethers here
		//vernamCrowdsaleToken.mintToken(_participant, tokens);        
		
		contributedInWei[_participant] = contributedInWei[_participant].add(_weiAmount);
		
		if(isThreeHotHoursActive == true) {
		    // threeHotHoursTokensMaxBalance[_participant] = threeHotHoursTokensMaxBalance[_participant].add(currentLevelTokens);
			threeHotHoursTokens[_participant] = threeHotHoursTokens[_participant].add(currentLevelTokens);
			boughtTokens[_participant] = boughtTokens[_participant].add(nextLevelTokens);
			whenBought[_participant] = block.timestamp;
		} else {	
			boughtTokens[_participant] = boughtTokens[_participant].add(currentLevelTokens.add(nextLevelTokens));
		}
		
		totalSoldTokens = totalSoldTokens.add(currentLevelTokens.add(nextLevelTokens));
		totalContributedWei = totalContributedWei.add(_weiAmount);
		
		emit TokensBought(_participant, _weiAmount, currentLevelTokens.add(nextLevelTokens));
		
		return true;
	}
	
	function privatePresaleBuy(address _participant, uint _weiAmount) internal {
		require(isInPrivatePreSale == true);
		require(totalSoldTokens < privatePreSaleTokensCap);
        require(block.timestamp < privatePreSaleEnd && totalSoldTokens < privatePreSaleTokensCap);
        
		uint tokens = _weiAmount.div(privatePreSalePriceOfTokenInWei);
		boughtTokens[_participant] = boughtTokens[_participant].add(tokens);
		
		totalSoldTokens = totalSoldTokens.add(tokens);
		
		emit TokensBought(_participant, _weiAmount, tokens);
	}
	
	function calculateAndCreateTokens(uint weiAmount) public returns (uint _tokensCurrentAmount, uint _tokensNextAmount) {

		if(block.timestamp < threeHotHoursEnd && totalSoldTokens < threeHotHoursTokensCap) {
		    (_tokensCurrentAmount, _tokensNextAmount) = tokensCalculator(weiAmount, threeHotHoursPriceOfTokenInWei, firstStagePriceOfTokenInWei, threeHotHoursCapInWei);
			
			return (_tokensCurrentAmount, _tokensNextAmount);
		}
		
		if(block.timestamp < firstStageEnd || totalSoldTokens < firstStageTokensCap) {
		    (_tokensCurrentAmount, _tokensNextAmount) = tokensCalculator(weiAmount, firstStagePriceOfTokenInWei, secondStagePriceOfTokenInWei, firstStageCapInWei);
			isThreeHotHoursActive = false;
			return (_tokensCurrentAmount, _tokensNextAmount);
		}
		
		if(block.timestamp < secondStageEnd || totalSoldTokens < secondStageTokensCap) {
			(_tokensCurrentAmount, _tokensNextAmount) = tokensCalculator(weiAmount, secondStagePriceOfTokenInWei, thirdStagePriceOfTokenInWei, secondStageCapInWei);
			return (_tokensCurrentAmount, _tokensNextAmount);
		}
		
		if(block.timestamp < thirdStageEnd || totalSoldTokens < thirdStageTokens && weiAmount > FIFTEEN_ETHERS) {
			(_tokensCurrentAmount, _tokensNextAmount) = tokensCalculator(weiAmount, thirdStageDiscountPriceOfTokenInWei, thirdStageDiscountPriceOfTokenInWei, thirdStageDiscountCapInWei);
			return (_tokensCurrentAmount, _tokensNextAmount);
		}
		
		if(block.timestamp < thirdStageEnd || totalSoldTokens < thirdStageTokens){
			(_tokensCurrentAmount, _tokensNextAmount) = tokensCalculator(weiAmount, thirdStagePriceOfTokenInWei, thirdStagePriceOfTokenInWei, thirdStageCapInWei);
			return (_tokensCurrentAmount, _tokensNextAmount);
		}
		
		revert();
	}
	
	function tokensCalculator(uint weiAmount, uint currentLevelPrice, uint nextLevelPrice, uint currentLevelCap) internal view returns (uint256, uint256){
	    uint currentAmountInWei = 0;
		uint remainingAmountInWei = 0;
		uint currentAmount = 0;
		uint nextAmount = 0;
		
		if(weiAmount.add(totalContributedWei) > currentLevelCap) {
		    remainingAmountInWei = (weiAmount.add(totalContributedWei)).sub(currentLevelCap);
		    currentAmountInWei = weiAmount.sub(remainingAmountInWei);
            currentAmount = currentAmountInWei.div(currentLevelPrice);
            nextAmount = remainingAmountInWei.div(nextLevelPrice);
	    } else {
	        currentAmount = weiAmount.div(currentLevelPrice);
			nextAmount = 0;
	    }

		return (currentAmount, nextAmount);
	}
	
	mapping(address => mapping(uint => uint)) getTokensBalance;
	mapping(address => mapping(uint => bool)) isTokensTaken;
	mapping(address => bool) isCalculated;
	function realaseThreeHotHour(address _participant) public onlyController returns(bool) {
		uint _amount = unlockTokensAmount(_participant);
		
		if(isCalculated[_participant] == false) {
		    calculateTokensForMonth(_participant);
		    isCalculated[_participant] = true;
		}
		
		threeHotHoursTokens[_participant] = threeHotHoursTokens[_participant].sub(_amount);
		boughtTokens[_participant] = boughtTokens[_participant].add(_amount);
		
		return true;
	}
	
	function calculateTokensForMonth(address _participant) {
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
        uint startTHHTime = whenBought[_participant];
		
		require(threeHotHoursTokens[_participant] > 0);
		
        if(block.timestamp < startTHHTime + FIRST_MONTH && isTokensTaken[_participant][0] == false) {
            isTokensTaken[_participant][0] == true;
            
            return getTokens(_participant, 1); // First month
        } 
        
        if(((block.timestamp >= startTHHTime + FIRST_MONTH) && (block.timestamp < startTHHTime + SECOND_MONTH)) 
            && isTokensTaken[_participant][1] == false) 
        {
            isTokensTaken[_participant][1] == true;
            
            return getTokens(_participant, 2); // Second month
        } 
        
        if(((block.timestamp >= startTHHTime + SECOND_MONTH) && (block.timestamp < startTHHTime + THIRD_MONTH)) 
            && isTokensTaken[_participant][2] == false) {
            isTokensTaken[_participant][2] == true;
            
            return getTokens(_participant, 3); // Third month
        } 
        
        if(((block.timestamp >= startTHHTime + THIRD_MONTH) && (block.timestamp < startTHHTime + FOURTH_MONTH)) 
            && isTokensTaken[_participant][3] == false) {
            isTokensTaken[_participant][3] == true;
            
            return getTokens(_participant, 4); // Forth month
        } 
        
        if(((block.timestamp >= startTHHTime + FOURTH_MONTH) && (block.timestamp < startTHHTime + FIFTH_MONTH)) 
            && isTokensTaken[_participant][4] == false) {
            isTokensTaken[_participant][4] == true;
            
            return getTokens(_participant, 5); // Fifth month
        } 
        
        if((block.timestamp >= startTHHTime + FIFTH_MONTH) 
            && isTokensTaken[_participant][5] == false) {
            isTokensTaken[_participant][5] == true;
            
            return getTokens(_participant, 6); // Last month
        }
    }
    
    function getTokens(address _participant, uint _period) internal returns(uint) {
        uint tokens = 0;
        for(uint month = 0; month < _period; month++) {
            if(isTokensTaken[_participant][month] == false) {
                tokens += getTokensBalance[_participant][month];
                getTokensBalance[_participant][month] = 0;
            }
            
            return tokens;
        }
    }
	
	function validatePurchase(address _participant, uint _weiAmount) pure internal {
        require(_participant != address(0));
        require(_weiAmount != 0);
    }
}
