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
	
	function setControler(address _controller) public onlyOwner {
		controller = _controller;
	}
}
contract VernamCrowdSale is Ownable {
	using SafeMath for uint256;
	
	uint constant FIFTEEN_ETHERS = 15 ether;
	uint constant minimumContribution = 100 finney;
	uint constant maximumContribution = 500 ether;
	
	uint constant FIRST_MONTH = 0;
	uint constant SECOND_MONTH = 1;
	uint constant THIRD_MONTH = 2;
	uint constant FORTH_MONTH = 3;
	uint constant FIFTH_MONTH = 4;
	uint constant SIXTH_MONTH = 5;	
	
	address public benecifiary;
	
	bool public isThreeHotHoursActive;
	bool public isInCrowdsale;
	
	uint public startTime;
	uint public totalSoldTokens;
	
	uint public totalContributedWei;
    
	uint constant public threeHotHoursDuration = 3 hours;
	uint constant public threeHotHoursPriceOfTokenInWei = 100000000000000 wei; //1 eth == 10 000
	uint public threeHotHoursTokensCap; 
	uint public threeHotHoursCapInWei; 
	uint public threeHotHoursEnd;

	uint public firstStageDuration = 7 days;
	uint public firstStagePriceOfTokenInWei = 200000000000000 wei;    //1 eth == 5000
	uint public firstStageTokensCap;

    uint public firstStageCapInWei;
	uint public firstStageEnd;
	
	uint constant public secondStageDuration = 6 days;
	uint constant public secondStagePriceOfTokenInWei = 400000000000000 wei;    //1 eth == 2500
	uint public secondStageTokensCap; 
    
    uint public secondStageCapInWei;
	uint public secondStageEnd;
	
	uint constant public thirdStageDuration = 26 days;
	uint constant public thirdStagePriceOfTokenInWei = 600000000000000 wei;          //1 eth == 1500
	
	uint constant public thirdStageDiscountPriceOfTokenInWei = 800000000000000 wei;  //1 eth == 1250
	
	uint public thirdStageTokens; 
	uint public thirdStageEnd;
	
	uint public thirdStageDiscountCapInWei; 
	uint public thirdStageCapInWei;
	
	uint constant public TOKENS_SOFT_CAP = 40000000000000000000000000;  // 40 000 000 with 18 decimals
	uint constant public TOKENS_HARD_CAP = 500000000000000000000000000; // 500 000 000 with 18 decimals
	
	uint constant public POW = 10 ** 18;
	
	// Constants for Realase Three Hot Hours
	uint constant public LOCK_TOKENS_DURATION = 30 days;
	uint public firstMonthEnd;
	uint public secondMonthEnd;
	uint public thirdMonthEnd;
	uint public fourthMonthEnd;
	uint public fifthMonthEnd;

	mapping(address => uint) public contributedInWei;
	mapping(address => uint) public threeHotHoursTokens;
	mapping(address => mapping(uint => uint)) public getTokensBalance;
	mapping(address => mapping(uint => bool)) public isTokensTaken;
	mapping(address => bool) public isCalculated;
	
	VernamCrowdSaleToken public vernamCrowdsaleToken;
	VernamWhiteListDeposit public vernamWhiteListDeposit;
	
	// Modifiers
    
    modifier afterCrowdsale() {
        require(block.timestamp > thirdStageEnd);
        _;
    }
    
    modifier isAfterThreeHotHours {
	    require(block.timestamp > threeHotHoursEnd);
	    _;
	}
	
    // Events
    event CrowdsaleActivated(uint startTime, uint endTime);
    event TokensBought(address participant, uint weiAmount, uint tokensAmount);
    event ReleasedTokens(uint _amount);
    event TokensClaimed(address _participant, uint tokensToGetFromWhiteList);
    
	function VernamCrowdSale(address _benecifiary,address _vernamWhiteListDepositAddress, address _vernamCrowdSaleTokenAddress) public {
		benecifiary = _benecifiary;
		vernamCrowdsaleToken = VernamCrowdSaleToken(_vernamCrowdSaleTokenAddress);
	    vernamWhiteListDeposit = VernamWhiteListDeposit(_vernamWhiteListDepositAddress);
        
		isInCrowdsale = false;
	}
	
	function activateCrowdSale() public onlyOwner {
	    
	    isThreeHotHoursActive = true;
		
		setTimeForCrowdsalePeriods();
		
		setCapForCrowdsalePeriods();

	    //uint whiteListParticipantsCount = vernamWhiteListDeposit.getCounter();
	    //uint tokensForClaim = tokensToGetFromWhiteList.mul(whiteListParticipantsCount);
	    //threeHotHoursTokensCap = threeHotHoursTokensCap.sub(tokensForClaim);
	    
		timeLock();
		
		isInCrowdsale = true;
		
	    emit CrowdsaleActivated(startTime, thirdStageEnd);
	}
	
	function() public payable {
		buyTokens(msg.sender,msg.value);
	}
	
	function buyTokens(address _participant, uint _weiAmount) public payable returns(bool) {
		require(isInCrowdsale == true);
		require(_weiAmount >= minimumContribution); // if value is smaller than most expensive stage price will count 0 tokens 
		require(_weiAmount <= maximumContribution);
		
		validatePurchase(_participant, _weiAmount);

		uint currentLevelTokens;
		uint nextLevelTokens;
		(currentLevelTokens, nextLevelTokens) = calculateAndCreateTokens(_weiAmount);
		uint tokensAmount = currentLevelTokens.add(nextLevelTokens);
		
		if(totalSoldTokens.add(tokensAmount) >= TOKENS_HARD_CAP) {
			isInCrowdsale = false;
		}
		
		// Transfer Ethers
		benecifiary.transfer(_weiAmount);
		
		contributedInWei[_participant] = contributedInWei[_participant].add(_weiAmount);
		
		if(isThreeHotHoursActive == true) {
			threeHotHoursTokens[_participant] = threeHotHoursTokens[_participant].add(currentLevelTokens);
			isCalculated[_participant] = false;
			if(nextLevelTokens > 0) {
				vernamCrowdsaleToken.mintToken(_participant, nextLevelTokens);
			    isThreeHotHoursActive = false;
			} 
		} else {	
			vernamCrowdsaleToken.mintToken(_participant, tokensAmount);        
		}
		
		totalSoldTokens = totalSoldTokens.add(tokensAmount);
		totalContributedWei = totalContributedWei.add(_weiAmount);
		
		emit TokensBought(_participant, _weiAmount, tokensAmount);
		
		return true;
	}
	
	function calculateAndCreateTokens(uint weiAmount) internal returns (uint _currentLevelTokensAmount, uint _nextLevelTokensAmount) {

		if(block.timestamp < threeHotHoursEnd && totalSoldTokens < threeHotHoursTokensCap) {
		    (_currentLevelTokensAmount, _nextLevelTokensAmount) = tokensCalculator(weiAmount, threeHotHoursPriceOfTokenInWei, firstStagePriceOfTokenInWei, threeHotHoursCapInWei);
			
			return (_currentLevelTokensAmount, _nextLevelTokensAmount);
		}
		
		if(block.timestamp < firstStageEnd || totalSoldTokens < firstStageTokensCap) {
			
			return getCurrentAndNextLevelTokensAmount(weiAmount, firstStagePriceOfTokenInWei, secondStagePriceOfTokenInWei, firstStageCapInWei, threeHotHoursTokensCap, firstStageTokensCap);
		}
		
		if(block.timestamp < secondStageEnd || totalSoldTokens < secondStageTokensCap) {			
			return getCurrentAndNextLevelTokensAmount(weiAmount, secondStagePriceOfTokenInWei, thirdStagePriceOfTokenInWei, secondStageCapInWei, firstStageTokensCap, secondStageTokensCap);
		}
		
		if(block.timestamp < thirdStageEnd || totalSoldTokens < thirdStageTokens && weiAmount > FIFTEEN_ETHERS) {
			return getCurrentAndNextLevelTokensAmount(weiAmount, thirdStageDiscountPriceOfTokenInWei, thirdStageDiscountPriceOfTokenInWei, thirdStageDiscountCapInWei, secondStageTokensCap, thirdStageTokens);
		}
		
		if(block.timestamp < thirdStageEnd || totalSoldTokens < thirdStageTokens){		
			return getCurrentAndNextLevelTokensAmount(weiAmount, thirdStagePriceOfTokenInWei, thirdStagePriceOfTokenInWei, thirdStageCapInWei, secondStageTokensCap, thirdStageTokens);
		}
		
		revert();
	}
	
	function release() public {
	    releaseThreeHotHourTokens(msg.sender);
	}
	
	function releaseThreeHotHourTokens(address _participant) public isAfterThreeHotHours returns(bool) { 
		if(isCalculated[_participant] == false) {
		    calculateTokensForMonth(_participant);
		    isCalculated[_participant] = true;
		}
		uint _amount = unlockTokensAmount(_participant);
		threeHotHoursTokens[_participant] = threeHotHoursTokens[_participant].sub(_amount);
		vernamCrowdsaleToken.mintToken(_participant, _amount);        

		emit ReleasedTokens(_amount);
		
		return true;
	}
	
	function getContributedAmountInWei(address _participant) public view returns (uint) {
        return contributedInWei[_participant];
    }
	
	function getCurrentAndNextLevelTokensAmount(uint256 weiAmount, uint256 currentStagePriceOfTokenInWei, uint256 nextStagePriceOfTokenInWei, uint256 currentStageCapInWei, uint256 previousTokenCap, uint256 currentTokenCap) internal returns (uint _currentLevelTokensAmount, uint _nextLevelTokensAmount) {
		
		(_currentLevelTokensAmount, _nextLevelTokensAmount) = tokensCalculator(weiAmount, currentStagePriceOfTokenInWei, nextStagePriceOfTokenInWei, currentStageCapInWei);
		
		if(totalSoldTokens < previousTokenCap) {
			currentTokenCap = (previousTokenCap.sub(totalSoldTokens)).add(currentTokenCap);
			currentStageCapInWei = currentStagePriceOfTokenInWei.mul((currentTokenCap).div(POW));
		}
		
		return (_currentLevelTokensAmount, _nextLevelTokensAmount);
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
	    currentLevelTokensAmount = currentLevelTokensAmount.mul(POW);
	    nextLevelTokensAmount = nextLevelTokensAmount.mul(POW);

		return (currentLevelTokensAmount, nextLevelTokensAmount);
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
		
        if(block.timestamp < firstMonthEnd && isTokensTaken[_participant][FIRST_MONTH] == false) {
            return getTokens(_participant, FIRST_MONTH.add(1)); // First month
        } 
        
        if(((block.timestamp >= firstMonthEnd) && (block.timestamp < secondMonthEnd)) 
            && isTokensTaken[_participant][SECOND_MONTH] == false) 
        {
            return getTokens(_participant, SECOND_MONTH.add(1)); // Second month
        } 
        
        if(((block.timestamp >= secondMonthEnd) && (block.timestamp < thirdMonthEnd)) 
            && isTokensTaken[_participant][THIRD_MONTH] == false) {
            return getTokens(_participant, THIRD_MONTH.add(1)); // Third month
        } 
        
        if(((block.timestamp >= thirdMonthEnd) && (block.timestamp < fourthMonthEnd)) 
            && isTokensTaken[_participant][FORTH_MONTH] == false) {
            return getTokens(_participant, FORTH_MONTH.add(1)); // Forth month
        } 
        
        if(((block.timestamp >= fourthMonthEnd) && (block.timestamp < fifthMonthEnd)) 
            && isTokensTaken[_participant][FIFTH_MONTH] == false) {
            return getTokens(_participant, FIFTH_MONTH.add(1)); // Fifth month
        } 
        
        if((block.timestamp >= fifthMonthEnd) 
            && isTokensTaken[_participant][SIXTH_MONTH] == false) {
            return getTokens(_participant, SIXTH_MONTH.add(1)); // Last month
        }
    }
    
    function getTokens(address _participant, uint _period) internal returns(uint) {
        uint tokens = 0;
        for(uint month = 0; month < _period; month++) { // We can make it <= and do not add 1 to constants 
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
	
	function setTimeForCrowdsalePeriods() internal {
		startTime = block.timestamp;
		threeHotHoursEnd = startTime.add(threeHotHoursDuration);
		firstStageEnd = threeHotHoursEnd.add(firstStageDuration);
		secondStageEnd = firstStageEnd.add(secondStageDuration);
		thirdStageEnd = secondStageEnd.add(thirdStageDuration);
	}

	function setCapForCrowdsalePeriods() internal {
		threeHotHoursTokensCap = 1000000000000000000000000;
		threeHotHoursCapInWei = threeHotHoursPriceOfTokenInWei.mul((threeHotHoursTokensCap).div(POW));

		firstStageTokensCap = 2000000000000000000000000;
		firstStageCapInWei = firstStagePriceOfTokenInWei.mul((firstStageTokensCap).div(POW));

		secondStageTokensCap = 3000000000000000000000000;
		secondStageCapInWei = secondStagePriceOfTokenInWei.mul((secondStageTokensCap).div(POW));

		thirdStageTokens = 5000000000000000000000000;
		thirdStageDiscountCapInWei = thirdStageDiscountPriceOfTokenInWei.mul((thirdStageTokens).div(POW));
		thirdStageCapInWei = thirdStagePriceOfTokenInWei.mul((thirdStageTokens).div(POW));
	}
	
	function timeLock() internal {
		firstMonthEnd = (startTime.add(LOCK_TOKENS_DURATION)).add(threeHotHoursDuration);
		secondMonthEnd = firstMonthEnd.add(LOCK_TOKENS_DURATION);
		thirdMonthEnd = secondMonthEnd.add(LOCK_TOKENS_DURATION);
		fourthMonthEnd = thirdMonthEnd.add(LOCK_TOKENS_DURATION);
		fifthMonthEnd = fourthMonthEnd.add(LOCK_TOKENS_DURATION);
	}
    
    /* 
    
    TODO after whitelist contract is ready 
    
    uint constant public whiteListAmountInWei = 10000000000000000; // 0.01 ETH
    uint public tokensToGetFromWhiteList = whiteListAmountInWei.div(threeHotHoursPriceOfTokenInWei);
    mapping(address => bool) getWhiteListTokens;
   
    function claimTokens(address _participant) public returns (bool) {
        bool isWhiteListed = vernamWhiteListDeposit.isWhiteList(_participant);
        require(isWhiteListed == true);
        require(getWhiteListTokens[_participant] == false);
        require(block.timestamp < threeHotHoursEnd);
        getWhiteListTokens[_participant] = true;
            
        threeHotHoursTokens[_participant] = threeHotHoursTokens[_participant].add(tokensToGetFromWhiteList);
        
        emit TokensClaimed(_participant, tokensToGetFromWhiteList);
        
        return true;
    }*/
}