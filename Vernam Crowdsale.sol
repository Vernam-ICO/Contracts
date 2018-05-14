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

	constructor() public {
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
	
	// After day 7 you can contribute only more than 10 ethers 
	uint constant TEN_ETHERS = 10 ether;
	// Minimum and maximum contribution amount
	uint constant minimumContribution = 100 finney;
	uint constant maximumContribution = 500 ether;
	
	// 
	uint constant FIRST_MONTH = 0;
	uint constant SECOND_MONTH = 1;
	uint constant THIRD_MONTH = 2;
	uint constant FORTH_MONTH = 3;
	uint constant FIFTH_MONTH = 4;
	uint constant SIXTH_MONTH = 5;	
	
	address public benecifiary;
	
    // Check if the crowdsale is active
	bool public isInCrowdsale;
	
	// The start time of the crowdsale
	uint public startTime;
	// The total sold tokens
	uint public totalSoldTokens;
	
	// The total contributed wei
	uint public totalContributedWei;

    // Public parameters for all the stages
	uint constant public threeHotHoursDuration = 3 hours;
	uint constant public threeHotHoursPriceOfTokenInWei = 63751115644524 wei; //0.00006375111564452380 ETH per Token // 15686 VRN per ETH
		
	uint public threeHotHoursTokensCap; 
	uint public threeHotHoursCapInWei; 
	uint public threeHotHoursEnd;

	uint public firstStageDuration = 8 days;
	uint public firstStagePriceOfTokenInWei = 85005100306018 wei;    //0.00008500510030601840 ETH per Token // 11764 VRN per ETH

	uint public firstStageEnd;
	
	uint constant public secondStageDuration = 12 days;
	uint constant public secondStagePriceOfTokenInWei = 90000900009000 wei;     //0.00009000090000900010 ETH per Token // 11111 VRN per ETH
    
	uint public secondStageEnd;
	
	uint constant public thirdStageDuration = 41 days;
	uint constant public thirdStagePriceOfTokenInWei = 106258633513973 wei;          //0.00010625863351397300 ETH per Token // 9411 VRN per ETH
	
	uint constant public thirdStageDiscountPriceOfTokenInWei = 95002850085503 wei;  //0.00009500285008550260 ETH per Token // 10526 VRN per ETH
	
	uint public thirdStageEnd;
	
	uint constant public TOKENS_HARD_CAP = 500000000000000000000000000; // 500 000 000 with 18 decimals
	
	// 18 decimals
	uint constant POW = 10 ** 18;
	
	// Constants for Realase Three Hot Hours
	uint constant public LOCK_TOKENS_DURATION = 30 days;
	uint public firstMonthEnd;
	uint public secondMonthEnd;
	uint public thirdMonthEnd;
	uint public fourthMonthEnd;
	uint public fifthMonthEnd;
    
    // Mappings
	mapping(address => uint) public contributedInWei;
	mapping(address => uint) public threeHotHoursTokens;
	mapping(address => mapping(uint => uint)) public getTokensBalance;
	mapping(address => mapping(uint => bool)) public isTokensTaken;
	mapping(address => bool) public isCalculated;
	
	VernamCrowdSaleToken public vernamCrowdsaleToken;
	
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
    
    /** @dev Constructor 
      * @param _benecifiary TODO
      * @param _vernamCrowdSaleTokenAddress The address of the crowdsale token.
      * 
      */
	constructor(address _benecifiary, address _vernamCrowdSaleTokenAddress) public {
		benecifiary = _benecifiary;
		vernamCrowdsaleToken = VernamCrowdSaleToken(_vernamCrowdSaleTokenAddress);
        
		isInCrowdsale = false;
	}
	
	/** @dev Function which activates the crowdsale 
      * Only the owner can call the function
      * Activates the threeHotHours and the whole crowdsale
      * Set the duration of crowdsale stages 
      * Set the tokens and wei cap of crowdsale stages 
      * Set the duration in which the tokens bought in threeHotHours will be locked
      */
	function activateCrowdSale() public onlyOwner {
	    		
		setTimeForCrowdsalePeriods();
		
		threeHotHoursTokensCap = 100000000000000000000000000;
		threeHotHoursCapInWei = threeHotHoursPriceOfTokenInWei.mul((threeHotHoursTokensCap).div(POW));
	    
		timeLock();
		
		isInCrowdsale = true;
		
	    emit CrowdsaleActivated(startTime, thirdStageEnd);
	}
	
	/** @dev Fallback function.
      * Provides functionality for person to buy tokens.
      */
	function() public payable {
		buyTokens(msg.sender,msg.value);
	}
	
	/** @dev Buy tokens function
      * Provides functionality for person to buy tokens.
      * @param _participant The investor which want to buy tokens.
      * @param _weiAmount The wei amount which the investor want to contribute.
      * @return success Is the buy tokens function called successfully.
      */
	function buyTokens(address _participant, uint _weiAmount) public payable returns(bool success) {
	    // Check if the crowdsale is active
		require(isInCrowdsale == true);
		// Check if the wei amount is between minimum and maximum contribution amount
		require(_weiAmount >= minimumContribution);
		require(_weiAmount <= maximumContribution);
		
		// Vaidates the purchase 
		// Check if the _participant address is not null and the weiAmount is not zero
		validatePurchase(_participant, _weiAmount);

		uint currentLevelTokens;
		uint nextLevelTokens;
		// Returns the current and next level tokens amount
		(currentLevelTokens, nextLevelTokens) = calculateAndCreateTokens(_weiAmount);
		uint tokensAmount = currentLevelTokens.add(nextLevelTokens);
		
		// If the hard cap is reached the crowdsale is not active anymore
		if(totalSoldTokens.add(tokensAmount) > TOKENS_HARD_CAP) {
			isInCrowdsale = false;
			return;
		}
		
		// Transfer Ethers
		benecifiary.transfer(_weiAmount);
		
		// Stores the participant's contributed wei
		contributedInWei[_participant] = contributedInWei[_participant].add(_weiAmount);
		
		// If it is in threeHotHours tokens will not be minted they will be stored in mapping threeHotHoursTokens
		if(threeHotHoursEnd > block.timestamp) {
			threeHotHoursTokens[_participant] = threeHotHoursTokens[_participant].add(currentLevelTokens);
			isCalculated[_participant] = false;
			// If we overflow threeHotHours tokens cap the tokens for the next level will not be zero
			// So we should deactivate the threeHotHours and mint tokens
			if(nextLevelTokens > 0) {
				vernamCrowdsaleToken.mintToken(_participant, nextLevelTokens);
			} 
		} else {	
			vernamCrowdsaleToken.mintToken(_participant, tokensAmount);        
		}
		
		// Store total sold tokens amount
		totalSoldTokens = totalSoldTokens.add(tokensAmount);
		
		// Store total contributed wei amount
		totalContributedWei = totalContributedWei.add(_weiAmount);
		
		emit TokensBought(_participant, _weiAmount, tokensAmount);
		
		return true;
	}
	
	/** @dev Function which gets the tokens amount for current and next level.
	  * If we did not overflow the current level cap, the next level tokens will be zero.
      * @return _currentLevelTokensAmount and _nextLevelTokensAmount Returns the calculated tokens for the current and next level
      * It is called by calculateAndCreateTokens function
      */
	function calculateAndCreateTokens(uint weiAmount) internal view returns (uint _currentLevelTokensAmount, uint _nextLevelTokensAmount) {

		if(block.timestamp < threeHotHoursEnd && totalSoldTokens < threeHotHoursTokensCap) {
		    (_currentLevelTokensAmount, _nextLevelTokensAmount) = tokensCalculator(weiAmount, threeHotHoursPriceOfTokenInWei, firstStagePriceOfTokenInWei, threeHotHoursCapInWei);
			return (_currentLevelTokensAmount, _nextLevelTokensAmount);
		}
		
		if(block.timestamp < firstStageEnd) {
		    _currentLevelTokensAmount = weiAmount.div(firstStagePriceOfTokenInWei);
	        _currentLevelTokensAmount = _currentLevelTokensAmount.mul(POW);
	        
		    return (_currentLevelTokensAmount, 0);
		}
		
		if(block.timestamp < secondStageEnd) {		
		    _currentLevelTokensAmount = weiAmount.div(secondStagePriceOfTokenInWei);
	        _currentLevelTokensAmount = _currentLevelTokensAmount.mul(POW);
	        
		    return (_currentLevelTokensAmount, 0);
		}
		
		if(block.timestamp < thirdStageEnd && weiAmount >= TEN_ETHERS) {
		    _currentLevelTokensAmount = weiAmount.div(thirdStageDiscountPriceOfTokenInWei);
	        _currentLevelTokensAmount = _currentLevelTokensAmount.mul(POW);
	        
		    return (_currentLevelTokensAmount, 0);
		}
		
		if(block.timestamp < thirdStageEnd){	
		    _currentLevelTokensAmount = weiAmount.div(thirdStagePriceOfTokenInWei);
	        _currentLevelTokensAmount = _currentLevelTokensAmount.mul(POW);
	        
		    return (_currentLevelTokensAmount, 0);
		}
		
		revert();
	}
	
	/** @dev Realase the tokens from the three hot hours.
      */
	function release() public {
	    releaseThreeHotHourTokens(msg.sender);
	}
	
	/** @dev Realase the tokens from the three hot hours.
	  * It can be called after the end of three hot hours
      * @param _participant The investor who want to release his tokens
      * @return success Is the release tokens function called successfully.
      */
	function releaseThreeHotHourTokens(address _participant) public isAfterThreeHotHours returns(bool success) { 
	    // Check if the _participants tokens are realased
	    // If not calculate his tokens for every month and set the isCalculated to true
		if(isCalculated[_participant] == false) {
		    calculateTokensForMonth(_participant);
		    isCalculated[_participant] = true;
		}
		
		// Unlock the tokens amount for the _participant
		uint _amount = unlockTokensAmount(_participant);
		
		// Substract the _amount from the threeHotHoursTokens mapping
		threeHotHoursTokens[_participant] = threeHotHoursTokens[_participant].sub(_amount);
		
		// Mint to the _participant vernamCrowdsaleTokens
		vernamCrowdsaleToken.mintToken(_participant, _amount);        

		emit ReleasedTokens(_amount);
		
		return true;
	}
	
	/** @dev Get contributed amount in wei.
      * @return contributedInWei[_participant].
      */
	function getContributedAmountInWei(address _participant) public view returns (uint) {
        return contributedInWei[_participant];
    }
	
	/** @dev Function which calculate tokens for every month (6 months).
      * @param weiAmount Participant's contribution in wei.
      * @param currentLevelPrice Price of the tokens for the current level.
      * @param nextLevelPrice Price of the tokens for the next level.
      * @param currentLevelCap Current level cap in wei.
      * @return _currentLevelTokensAmount and _nextLevelTokensAmount Returns the calculated tokens for the current and next level
      * It is called by three hot hours
      */
      
	function tokensCalculator(uint weiAmount, uint currentLevelPrice, uint nextLevelPrice, uint currentLevelCap) internal view returns (uint _currentLevelTokensAmount, uint _nextLevelTokensAmount){
	    uint currentAmountInWei = 0;
		uint remainingAmountInWei = 0;
		uint currentLevelTokensAmount = 0;
		uint nextLevelTokensAmount = 0;
		
		// Check if the contribution overflows and you should buy tokens on next level price
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
	
	/** @dev Function which calculate tokens for every month (6 months).
      * @param _participant The investor whose tokens are calculated.
      * It is called once from the releaseThreeHotHourTokens function
      */
	function calculateTokensForMonth(address _participant) internal {
	    // Get the max balance of the participant  
	    uint maxBalance = threeHotHoursTokens[_participant];
	    
	    // Start from 10% for the first three months
	    uint percentage = 10;
	    for(uint month = 0; month < 6; month++) {
	        // The fourth month the unlock tokens percentage is increased by 10% and for the fourth and fifth month will be 20%
	        // It will increase one more by 10% in the last month and will become 30% 
	        if(month == 3 || month == 5) {
	            percentage += 10;
	        }
	        
	        // Set the participant at which month how much he will get
	        getTokensBalance[_participant][month] = maxBalance.div(percentage);
	        
	        // Set for every month false to see the tokens for the month is not get it 
	        isTokensTaken[_participant][month] = false; 
	    }
	}
	
		
	/** @dev Function which validates if the participan is not null address and the wei amount is not zero
      * @param _participant The investor who want to unlock his tokens
      * @return _tokensAmount Tokens which are unlocked
      */
	function unlockTokensAmount(address _participant) internal returns (uint _tokensAmount) {
	    // Check if the _participant have tokens in threeHotHours stage
		require(threeHotHoursTokens[_participant] > 0);
		
		// Check if the _participant got his tokens in first month and if the time for the first month end has come 
        if(block.timestamp < firstMonthEnd && isTokensTaken[_participant][FIRST_MONTH] == false) {
            // Go and get the tokens for the current month
            return getTokens(_participant, FIRST_MONTH.add(1)); // First month
        } 
        
        // Check if the _participant got his tokens in second month and if the time is in the period between first and second month end
        if(((block.timestamp >= firstMonthEnd) && (block.timestamp < secondMonthEnd)) 
            && isTokensTaken[_participant][SECOND_MONTH] == false) {
            // Go and get the tokens for the current month
            return getTokens(_participant, SECOND_MONTH.add(1)); // Second month
        } 
        
        // Check if the _participant got his tokens in second month and if the time is in the period between second and third month end
        if(((block.timestamp >= secondMonthEnd) && (block.timestamp < thirdMonthEnd)) 
            && isTokensTaken[_participant][THIRD_MONTH] == false) {
            // Go and get the tokens for the current month
            return getTokens(_participant, THIRD_MONTH.add(1)); // Third month
        } 
        
        // Check if the _participant got his tokens in second month and if the time is in the period between third and fourth month end
        if(((block.timestamp >= thirdMonthEnd) && (block.timestamp < fourthMonthEnd)) 
            && isTokensTaken[_participant][FORTH_MONTH] == false) {
            // Go and get the tokens for the current month
            return getTokens(_participant, FORTH_MONTH.add(1)); // Forth month
        } 
        
        // Check if the _participant got his tokens in second month and if the time is in the period between forth and fifth month end
        if(((block.timestamp >= fourthMonthEnd) && (block.timestamp < fifthMonthEnd)) 
            && isTokensTaken[_participant][FIFTH_MONTH] == false) {
            // Go and get the tokens for the current month
            return getTokens(_participant, FIFTH_MONTH.add(1)); // Fifth month
        } 
        
        // Check if the _participant got his tokens in second month and if the time is after the end of the fifth month
        if((block.timestamp >= fifthMonthEnd) 
            && isTokensTaken[_participant][SIXTH_MONTH] == false) {
            return getTokens(_participant, SIXTH_MONTH.add(1)); // Last month
        }
    }
    
    /** @dev Function for getting the tokens for unlock
      * @param _participant The investor who want to unlock his tokens
      * @param _period The period for which will be unlocked the tokens
      * @return tokensAmount Returns the amount of tokens for unlocing
      */
    function getTokens(address _participant, uint _period) internal returns(uint tokensAmount) {
        uint tokens = 0;
        for(uint month = 0; month < _period; month++) {
            // Check if the tokens fot the current month unlocked
            if(isTokensTaken[_participant][month] == false) { 
                // Set the isTokensTaken to true
                isTokensTaken[_participant][month] = true;
                
                // Calculates the tokens
                tokens += getTokensBalance[_participant][month];
                
                // Set the balance for the curren month to zero
                getTokensBalance[_participant][month] = 0;
            }
        }
        
        return tokens;
    }
	
	/** @dev Function which validates if the participan is not null address and the wei amount is not zero
      * @param _participant The investor who want to buy tokens
      * @param _weiAmount The amount of wei which the investor want to contribute
      */
	function validatePurchase(address _participant, uint _weiAmount) pure internal {
        require(_participant != address(0));
        require(_weiAmount != 0);
    }
	
	 /** @dev Function which set the duration of crowdsale stages
      * Called by the activateCrowdSale function 
      */
	function setTimeForCrowdsalePeriods() internal {
		startTime = block.timestamp;
		threeHotHoursEnd = startTime.add(threeHotHoursDuration);
		firstStageEnd = threeHotHoursEnd.add(firstStageDuration);
		secondStageEnd = firstStageEnd.add(secondStageDuration);
		thirdStageEnd = secondStageEnd.add(thirdStageDuration);
	}
	
	/** @dev Function which set the duration in which the tokens bought in threeHotHours will be locked
      * Called by the activateCrowdSale function 
      */
	function timeLock() internal {
		firstMonthEnd = (startTime.add(LOCK_TOKENS_DURATION)).add(threeHotHoursDuration);
		secondMonthEnd = firstMonthEnd.add(LOCK_TOKENS_DURATION);
		thirdMonthEnd = secondMonthEnd.add(LOCK_TOKENS_DURATION);
		fourthMonthEnd = thirdMonthEnd.add(LOCK_TOKENS_DURATION);
		fifthMonthEnd = fourthMonthEnd.add(LOCK_TOKENS_DURATION);
	}
	
	function getPrice(uint256 time, uint256 weiAmount) public view returns (uint levelPrice) {

		if(time < threeHotHoursEnd && totalSoldTokens < threeHotHoursTokensCap) {
            return threeHotHoursPriceOfTokenInWei;
		}
		
		if(time < firstStageEnd) {
            return firstStagePriceOfTokenInWei;
		}
		
		if(time < secondStageEnd) {
            return secondStagePriceOfTokenInWei;
		}
		
		if(time < thirdStageEnd && weiAmount > TEN_ETHERS) {
            return thirdStageDiscountPriceOfTokenInWei;
		}
		
		if(time < thirdStageEnd){		
		    return thirdStagePriceOfTokenInWei;
		}
	}
	
	function setBenecifiary(address _newBenecifiary) public onlyOwner {
		benecifiary = _newBenecifiary;
	}
}