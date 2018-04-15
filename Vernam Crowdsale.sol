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
		
	address public benecifiary;
	
	bool public isThreeHotHoursActive;
	bool public isInCrowdsale; // NEW
	
	uint public startTime;
	uint public totalSoldTokens;
	uint constant FIFTEEN_ETHERS = 15 ether;
	uint constant minimumContribution = 100 finney;
	uint constant maximumContribution = 500 ether;
	uint public totalContributedWei;
    
	uint constant public threeHotHoursDuration = 3 hours;
	uint constant public threeHotHoursPriceOfTokenInWei = 100000000000000 wei; //1 eth == 10 000
	uint public threeHotHoursTokensCap; //= 100000000000000000000000; // 100 000 tokens
	uint public threeHotHoursCapInWei; //= threeHotHoursPriceOfTokenInWei.mul((threeHotHoursTokensCap).div(POW));
	uint public threeHotHoursEnd;

	uint public firstStageDuration = 24 hours;
	uint public firstStagePriceOfTokenInWei = 200000000000000 wei;    //1 eth == 5000
	uint public firstStageTokensCap; // = 100000000000000000000000; // 100 000 tokens  //maybe not constant because we must recalculate if previous have remainig

    uint public firstStageCapInWei; // = firstStagePriceOfTokenInWei.mul((firstStageTokensCap).div(POW));
	uint public firstStageEnd;
	
	uint constant public secondStageDuration = 6 days;
	uint constant public secondStagePriceOfTokenInWei = 400000000000000 wei;    //1 eth == 2500
	uint public secondStageTokensCap; // = 100000000000000000000000; // 100 000 tokens       //maybe not constant because we must recalculate if previous have remainig
    
    uint public secondStageCapInWei; // = secondStagePriceOfTokenInWei.mul((secondStageTokensCap).div(POW));
	uint public secondStageEnd;
	
	uint constant public thirdStageDuration = 26 days;
	uint constant public thirdStagePriceOfTokenInWei = 600000000000000 wei;          //1 eth == 1500
	
	uint constant public thirdStageDiscountPriceOfTokenInWei = 800000000000000 wei;  //1 eth == 1250
	
	uint public thirdStageTokens; // = 100000000000000000000000; // 100 000 tokens //maybe not constant because we must recalculate if previous have remainig
	uint public thirdStageEnd;
	
	uint public thirdStageDiscountCapInWei; // = thirdStageDiscountPriceOfTokenInWei.mul((thirdStageTokens).div(POW));
	uint public thirdStageCapInWei; // = thirdStagePriceOfTokenInWei.mul((thirdStageTokens).div(POW));
	
	uint constant public TOKENS_SOFT_CAP = 40000000000000000000000000;  // 40 000 000 with 18 decimals
	uint constant public TOKENS_HARD_CAP = 500000000000000000000000000; // 500 000 000 with 18 decimals
	
	uint constant public POW = 10 ** 18;
	
	// Constants for Realase Three Hot Hours
	uint constant public LOCK_TOKENS_DURATION = 30 days;
	uint public FIRST_MONTH_END ;
	uint public SECOND_MONTH_END ;
	uint public THIRD_MONTH_END ;
	uint public FOURTH_MONTH_END ;
	uint public FIFTH_MONTH_END ;

	mapping(address => uint) public contributedInWei;
	mapping(address => uint) public threeHotHoursTokens;
	mapping(address => mapping(uint => uint)) public getTokensBalance;
	mapping(address => mapping(uint => bool)) public isTokensTaken;
	mapping(address => bool) public isCalculated;
	
	VernamCrowdSaleToken public vernamCrowdsaleToken;
	VernamWhiteListDeposit public vernamWhiteListDeposit;
	
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
		
		isInCrowdsale = true; // NEW
		
	    emit CrowdsaleActivated(startTime, thirdStageEnd);
	}

	function setTimeForCrowdsalePeriods() internal {
		startTime = block.timestamp;
		threeHotHoursEnd = startTime.add(threeHotHoursDuration);
		firstStageEnd = threeHotHoursEnd.add(firstStageDuration);
		secondStageEnd = firstStageEnd.add(secondStageDuration);
		thirdStageEnd = secondStageEnd.add(thirdStageDuration);
	}

	function setCapForCrowdsalePeriods() internal {
		threeHotHoursTokensCap = 100000000000000000000000;
		threeHotHoursCapInWei = threeHotHoursPriceOfTokenInWei.mul((threeHotHoursTokensCap).div(POW));

		firstStageTokensCap = 100000000000000000000000;
		firstStageCapInWei = firstStagePriceOfTokenInWei.mul((firstStageTokensCap).div(POW));

		secondStageTokensCap = 100000000000000000000000;
		secondStageCapInWei = secondStagePriceOfTokenInWei.mul((secondStageTokensCap).div(POW));

		thirdStageTokens = 100000000000000000000000;
		thirdStageDiscountCapInWei = thirdStageDiscountPriceOfTokenInWei.mul((thirdStageTokens).div(POW));
		thirdStageCapInWei = thirdStagePriceOfTokenInWei.mul((thirdStageTokens).div(POW));
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
		require(isInCrowdsale == true); // NEW
		require(_weiAmount >= minimumContribution); // if value is smaller than most expensive stage price will count 0 tokens 
		require(_weiAmount <= maximumContribution);
		
		validatePurchase(_participant, _weiAmount);

		uint currentLevelTokens;
		uint nextLevelTokens;
		(currentLevelTokens, nextLevelTokens) = calculateAndCreateTokens(_weiAmount);
		uint tokensAmount = currentLevelTokens.add(nextLevelTokens);
		
		// NEW
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
		    (_currentLevelTokensAmount, _nextLevelTokensAmount) = tokensCalculator(weiAmount, firstStagePriceOfTokenInWei, secondStagePriceOfTokenInWei, firstStageCapInWei);
			
			if(totalSoldTokens < threeHotHoursTokensCap) {
			    firstStageTokensCap = (threeHotHoursTokensCap.sub(totalSoldTokens)).add(firstStageTokensCap);
                firstStageCapInWei = firstStagePriceOfTokenInWei.mul((firstStageTokensCap).div(POW));
			}
			
			isThreeHotHoursActive = false;
			
			return (_currentLevelTokensAmount, _nextLevelTokensAmount);
		}
		
		if(block.timestamp < secondStageEnd || totalSoldTokens < secondStageTokensCap) {
			(_currentLevelTokensAmount, _nextLevelTokensAmount) = tokensCalculator(weiAmount, secondStagePriceOfTokenInWei, thirdStagePriceOfTokenInWei, secondStageCapInWei);
			
			if(totalSoldTokens < firstStageTokensCap) {
			    secondStageTokensCap = (firstStageTokensCap.sub(totalSoldTokens)).add(secondStageTokensCap);
    
                secondStageCapInWei = secondStagePriceOfTokenInWei.mul((secondStageTokensCap).div(POW));
			}
			
			return (_currentLevelTokensAmount, _nextLevelTokensAmount);
		}
		
		if(block.timestamp < thirdStageEnd || totalSoldTokens < thirdStageTokens && weiAmount > FIFTEEN_ETHERS) {
			(_currentLevelTokensAmount, _nextLevelTokensAmount) = tokensCalculator(weiAmount, thirdStageDiscountPriceOfTokenInWei, thirdStageDiscountPriceOfTokenInWei, thirdStageDiscountCapInWei);
			
			if(totalSoldTokens < secondStageTokensCap) {
			    thirdStageTokens = (secondStageTokensCap.sub(totalSoldTokens)).add(thirdStageTokens);
    
                thirdStageDiscountCapInWei = thirdStageDiscountPriceOfTokenInWei.mul((thirdStageTokens).div(POW));
			}
			
			return (_currentLevelTokensAmount, _nextLevelTokensAmount);
		}
		
		if(block.timestamp < thirdStageEnd || totalSoldTokens < thirdStageTokens){
			(_currentLevelTokensAmount, _nextLevelTokensAmount) = tokensCalculator(weiAmount, thirdStagePriceOfTokenInWei, thirdStagePriceOfTokenInWei, thirdStageCapInWei);
			
			if(totalSoldTokens < secondStageTokensCap) {
			    thirdStageTokens = (secondStageTokensCap.sub(totalSoldTokens)).add(thirdStageTokens);
                
                thirdStageCapInWei = thirdStagePriceOfTokenInWei.mul((thirdStageTokens).div(POW));
			}
			
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
	    currentLevelTokensAmount = currentLevelTokensAmount.mul(POW);
	    nextLevelTokensAmount = nextLevelTokensAmount.mul(POW);

		return (currentLevelTokensAmount, nextLevelTokensAmount);
	}
	
	function releaseThreeHotHourTokens(address _participant) public isAfterThreeHotHours returns(bool) { 
		uint _amount = unlockTokensAmount(_participant);
		
		if(isCalculated[_participant] == false) {
		    calculateTokensForMonth(_participant);
		    isCalculated[_participant] = true;
		}
		
		threeHotHoursTokens[_participant] = threeHotHoursTokens[_participant].sub(_amount);
		vernamCrowdsaleToken.mintToken(_participant, _amount);        

		emit ReleasedTokens(_amount);
		
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
	
	uint public constant FIRST_MONTH = 0;
	uint public constant SECOND_MONTH = 1;
	uint public constant THIRD_MONTH = 2;
	uint public constant FORTH_MONTH = 3;
	uint public constant FIFTH_MONTH = 4;
	uint public constant SIXTH_MONTH = 5;
	
	function unlockTokensAmount(address _participant) internal returns (uint) {
		require(threeHotHoursTokens[_participant] > 0);
		
        if(block.timestamp < FIRST_MONTH_END && isTokensTaken[_participant][FIRST_MONTH] == false) {
            return getTokens(_participant, FIRST_MONTH.add(1)); // First month
        } 
        
        if(((block.timestamp >= FIRST_MONTH_END) && (block.timestamp < SECOND_MONTH_END)) 
            && isTokensTaken[_participant][SECOND_MONTH] == false) 
        {
            return getTokens(_participant, SECOND_MONTH.add(1)); // Second month
        } 
        
        if(((block.timestamp >= SECOND_MONTH_END) && (block.timestamp < THIRD_MONTH_END)) 
            && isTokensTaken[_participant][THIRD_MONTH] == false) {
            return getTokens(_participant, THIRD_MONTH.add(1)); // Third month
        } 
        
        if(((block.timestamp >= THIRD_MONTH_END) && (block.timestamp < FOURTH_MONTH_END)) 
            && isTokensTaken[_participant][FORTH_MONTH] == false) {
            return getTokens(_participant, FORTH_MONTH.add(1)); // Forth month
        } 
        
        if(((block.timestamp >= FOURTH_MONTH_END) && (block.timestamp < FIFTH_MONTH_END)) 
            && isTokensTaken[_participant][FIFTH_MONTH] == false) {
            return getTokens(_participant, FIFTH_MONTH.add(1)); // Fifth month
        } 
        
        if((block.timestamp >= FIFTH_MONTH_END) 
            && isTokensTaken[_participant][SIXTH_MONTH] == false) {
            return getTokens(_participant, SIXTH_MONTH.add(1)); // Last month
        }
    }
    
    function getTokens(address _participant, uint _period) internal returns(uint) {
        uint tokens = 0;
        for(uint month = 0; month < _period; month++) { // We can make it <= and do not add 1 to constants 
            if(isTokensTaken[_participant][month] == false) { // We can check is there a balance in getTokensBalance() and we do not need this boolean
                isTokensTaken[_participant][month] == true; // we do not need it
                
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
    
    function setContributedAmountInWei(address _participant) public softCapNotReached afterCrowdsale onlyController returns (bool) { //view ???
        contributedInWei[_participant] = 0;
        
        return true;
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