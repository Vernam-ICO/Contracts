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
	address public Controller;
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	function Ownable() public {
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}
	
	modifier onlyController() {
		require(msg.sender == Controller);
		_;
	}


	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}
	
	function setController(address _controllerAddress) public onlyOwner {
		Controller = _controllerAddress;
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
	
	uint public privatePreSaleEnd;

	uint constant public threeHotHoursDuration = 3 hours;
	uint constant public threeHotHoursPriceOfTokenInWei = 100000000000000 wei; //1 eth == 10 000
	uint constant public threeHotHoursTokensCap = 100000; // 100 000 tokens
	uint constant public threeHotHoursCapInWei = threeHotHoursPriceOfTokenInWei.mul(threeHotHoursTokensCap);

	uint public threeHotHoursEnd;
	
	uint constant public firstStageDuration = 24 hours;
	uint constant public firstStagePriceOfTokenInWei = 200000000000000 wei;    //1 eth == 5000
	uint constant public firstStageTokensCap = 100000; // 100 000 tokens  //maybe not constant because we must recalculate if previous have remainig
    uint constant public firstStageCapInWei = firstStagePriceOfTokenInWei.mul(firstStageTokensCap);
    
	uint public firstStageEnd;
	
	uint constant public secondStageDuration = 6 days;
	uint constant public secondStagePriceOfTokenInWei = 400000000000000 wei; //1 eth == 2500
	uint constant public secondStageTokensCap = 100000; // 100 000 tokens       //maybe not constant because we must recalculate if previous have remainig
    uint constant public secondStageCapInWei = secondStagePriceOfTokenInWei.mul(secondStageTokensCap);
    
	uint public secondStageEnd;
	
	uint constant public thirdStageDuration = 26 days;
	uint constant public thirdStagePriceOfTokenInWei = 600000000000000 wei;          //1 eth == 1500
	
	uint constant public thirdStageDiscountPriceOfTokenInWei = 800000000000000 wei; //1 eth == 1250
	
	uint constant public thirdStageTokens = 100000; // 100 000 tokens //maybe not constant because we must recalculate if previous have remainig
	uint public thirdStageEnd;
	
	uint constant public thirdStageDiscountCapInWei = thirdStageDiscountPriceOfTokenInWei.mul(thirdStageTokens);
	uint constant public thirdStageCapInWei = thirdStagePriceOfTokenInWei.mul(thirdStageTokens);
	
	uint constant public TokensHardCap = 500000000000000000000000000;  //500 000 000 with 18 decimals
	
	// Constants for Realase Three Hot Hours
	uint constant public LOCK_TOKENS_DURATION = 30 days;
	uint constant public FIRST_MONTH = LOCK_TOKENS_DURATION;
	uint constant public SECOND_MONTH = LOCK_TOKENS_DURATION + FIRST_MONTH;
	uint constant public THIRD_MONTH = LOCK_TOKENS_DURATION + SECOND_MONTH;
	uint constant public FOURTH_MONTH = LOCK_TOKENS_DURATION + THIRD_MONTH;
	uint constant public FIFTH_MONTH = LOCK_TOKENS_DURATION + FOURTH_MONTH;
	uint constant public SIXTH_MONTH = LOCK_TOKENS_DURATION + FIFTH_MONTH;
	
	mapping(address => uint256) whenBought;
	
	mapping(address => uint256) public contributedInWei;
	mapping(address => uint256) public boughtTokens;
	
	mapping(address => uint256) public threeHotHoursTokens;
	// VernamCrowdsaleToken public VCT;


	function VernamCrowdSale() public {
		benecifiary = 0xca35b7d915458ef540ade6068dfe2f44e8fa733c;
		// VCT = VernamCrowdsaleToken(address);
		
		startTime = block.timestamp;
		privatePreSaleEnd = startTime.add(privatePreSaleDuration);
		isInPrivatePreSale = true;
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
	}
	
	function() public payable {
		buyTokens(msg.sender,msg.value);
	}
	
	function buyTokens(address _participant, uint256 _weiAmount) public payable returns(bool) {
		require(_weiAmount >= minimumContribution); // if value is smaller than most expensive stage price will count 0 tokens 
		
		validatePurchase(_participant, _weiAmount);
		
		if (isInPrivatePreSale = true) {
		    privatePresaleBuy(_participant, _weiAmount);  
		    return true;
		}
		
		uint256 currentLevelTokens;
		uint256 nextLevelTokens;
		(currentLevelTokens, nextLevelTokens) = calculateAndCreateTokens(_weiAmount);
		
		require(totalSoldTokens.add(currentLevelTokens.add(nextLevelTokens)) <= TokensHardCap);
		// transfer ethers here
		//VCT.mintToken(_participant, tokens);        
		
		contributedInWei[_participant] = contributedInWei[_participant].add(_weiAmount);
		
		if(isThreeHotHoursActive == true) {
			threeHotHoursTokens[_participant] = threeHotHoursTokens[_participant].add(currentLevelTokens);
			boughtTokens[_participant] = boughtTokens[_participant].add(nextLevelTokens);
			whenBought[_participant] = block.timestamp;
		} else {	
			boughtTokens[_participant] = boughtTokens[_participant].add(currentLevelTokens.add(nextLevelTokens));
		}
		
		totalSoldTokens = totalSoldTokens.add(currentLevelTokens.add(nextLevelTokens));
		totalContributedWei = totalContributedWei.add(_weiAmount);
		
		//Event
		
		return true;
	}
	
	function privatePresaleBuy(address _participant, uint256 _weiAmount) internal {
		require(isInPrivatePreSale == true);
		require(totalSoldTokens < privatePreSaleTokensCap);
        require(block.timestamp < privatePreSaleEnd && totalSoldTokens < privatePreSaleTokensCap);
        
		uint tokens = _weiAmount.div(privatePreSalePriceOfTokenInWei);
		boughtTokens[_participant] = boughtTokens[_participant].add(tokens);
		
		totalSoldTokens = totalSoldTokens.add(tokens);
	}
	
	function calculateAndCreateTokens(uint256 weiAmount) public returns (uint256 _tokensCurrentAmount, uint256 _tokensNextAmount) {

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
	
	function tokensCalculator(uint256 weiAmount, uint256 currentLevelPrice, uint256 nextLevelPrice, uint256 currentLevelCap) internal view returns (uint256, uint256){
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
	
	mapping(address => uint256) percentage;
	mapping(address => mapping(uint256 => bool)) getTokens;
	
	function realaseThreeHotHour(address _participant) public onlyController returns(bool) {
		uint256 _amount = unlockTokensAmount(_participant);
		
		threeHotHoursTokens[_participant] = threeHotHoursTokens[_participant].sub(_amount);
		boughtTokens[_participant] = boughtTokens[_participant].add(_amount);
		
		return true;
	}
	
	function unlockTokensAmount(address _participant) internal view returns (uint) {
        uint startTHHTime = whenBought[_participant];
        uint _balanceAtTHH = threeHotHoursTokens[_participant];
		
		require(_balanceAtTHH > 0);
		
        if(block.timestamp < startTHHTime + FIRST_MONTH && getTokens[msg.sender][startTHHTime + FIRST_MONTH] == false) {
            percentage[msg.sender] += 10;
            getTokens[msg.sender][startTHHTime + FIRST_MONTH] = true;
            
            return (_balanceAtTHH.mul(percentage[msg.sender])).div(100);
        } 
        
        if(block.timestamp < startTHHTime + SECOND_MONTH && getTokens[msg.sender][startTHHTime + SECOND_MONTH] == false) 
        {
            percentage[msg.sender] = 20 - percentage[msg.sender];
            getTokens[msg.sender][startTHHTime + SECOND_MONTH] = true;
            
            return (_balanceAtTHH.mul(percentage[msg.sender])).div(100);
        } 
        
        if(block.timestamp < startTHHTime + THIRD_MONTH && getTokens[msg.sender][startTHHTime + THIRD_MONTH] == false) {
            percentage[msg.sender] = 30 - percentage[msg.sender];
            getTokens[msg.sender][startTHHTime + THIRD_MONTH] = true;
            
            return (_balanceAtTHH.mul(percentage[msg.sender])).div(100);
        } 
        
        if(block.timestamp < startTHHTime + FOURTH_MONTH && getTokens[msg.sender][startTHHTime + FOURTH_MONTH] == false) {
            percentage[msg.sender] = 50 - percentage[msg.sender];
            getTokens[msg.sender][startTHHTime + FOURTH_MONTH] = true;
            
            return (_balanceAtTHH.mul(percentage[msg.sender])).div(100);
        } 
        
        if(block.timestamp < startTHHTime + FIFTH_MONTH && getTokens[msg.sender][startTHHTime + FIFTH_MONTH] == false) {
            percentage[msg.sender] = 70 - percentage[msg.sender];
            getTokens[msg.sender][startTHHTime + FIFTH_MONTH] = true;
            
            return (_balanceAtTHH.mul(percentage[msg.sender])).div(100);
        } 
        
        if(block.timestamp < startTHHTime + SIXTH_MONTH && getTokens[msg.sender][startTHHTime + FIFTH_MONTH] == false) {
            getTokens[msg.sender][startTHHTime + SIXTH_MONTH] == true;
            
            return _balanceAtTHH;
        }
    }
	
	function validatePurchase(address _participant, uint256 _weiAmount) pure internal {
        require(_participant != address(0));
        require(_weiAmount != 0);
    }
}
