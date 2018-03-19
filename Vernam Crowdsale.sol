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

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	function Ownable() public {
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}

}

contract VernamCrowdSale is Ownable {
	using SafeMath for uint256;
		
	address public benecifiary;
	
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
	
	mapping(address => OrderDetail) public OrdersDetail;

	// VernamCrowdsaleToken public VCT;
	
	// Events
	event Refunded(address _participant, uint amountInWei);
	
	struct OrderDetail {
		uint256 privatePresaleWEI;
		uint256 privatePresaleTokens;

		uint256 threeHotHoursWEI;
		uint256 threeHotHoursTokens;

		uint256 firstStageWEI;
		uint256 firstStageTokens;

		uint256 secondStageWEI;
		uint256 secondStageTokens;

		uint256 thirdStageWithDiscountWEI;
		uint256 thirdStageWithDiscountTokens;

		uint256 thirdStageWEI;
		uint256 thirdStageTokens;
	}


	function VernamCrowdSale() public {
		benecifiary = 0xca35b7d915458ef540ade6068dfe2f44e8fa733c;
		// VCT = VernamCrowdsaleToken(address);
	}
	
	function activateCrowdSale() public onlyOwner {
		startTime = block.timestamp;
		privatePreSaleEnd = startTime.add(privatePreSaleDuration);
		threeHotHoursEnd = privatePreSaleEnd.add(threeHotHoursDuration);
		firstStageEnd = threeHotHoursEnd.add(firstStageDuration);
		secondStageEnd = firstStageEnd.add(secondStageDuration);
		thirdStageEnd = secondStageEnd.add(thirdStageDuration);
	}
	
	function() public payable {
		buyTokens(msg.sender,msg.value);
	}
	
	function buyTokens(address _participant, uint256 _weiAmount) public payable returns(bool) {
		//require(_weiAmount >= minimumContribution); // if value is smaller than most expensive stage price will count 0 tokens 
		//uint256 tokens = calculateAndCreateTokens(_weiAmount);
		//require(totalSoldTokens.add(tokens) <= TokensHardCap);
		// writeOrder(_participant, _weiAmount, tokens);
		//VCT.mintToken(_participant, tokens);        
		//totalSoldTokens = totalSoldTokens.add(tokens);
		//totalContributedWei = totalContributedWei.add(_weiAmount);
		//return true;
		
		//Event

	}
	
	function calculateAndCreateTokens(uint256 weiAmount) public returns (uint256 _tokensAmount) {
		
		// The private presale operations must be in another functions 
		/*if(block.timestamp < privatePreSaleEnd && totalSoldTokens < privatePreSaleTokens){
			return privatePreSalePrice;
		}*/
		
		// Safe math will be used 
		if(block.timestamp < threeHotHoursEnd && totalSoldTokens < threeHotHoursTokensCap) {
		    _tokensAmount = tokensCalculator(weiAmount, threeHotHoursPriceOfTokenInWei, firstStagePriceOfTokenInWei, threeHotHoursCapInWei);
			return _tokensAmount;
		}
		
		if(block.timestamp < firstStageEnd && totalSoldTokens < firstStageTokensCap) {
		    _tokensAmount = tokensCalculator(weiAmount, firstStagePriceOfTokenInWei, secondStagePriceOfTokenInWei, firstStageCapInWei);
			return _tokensAmount;
		}
		
		if(block.timestamp < secondStageEnd && totalSoldTokens < secondStageTokensCap) {
			_tokensAmount = tokensCalculator(weiAmount, secondStagePriceOfTokenInWei, thirdStagePriceOfTokenInWei, secondStageCapInWei);
			return _tokensAmount;
		}
		
		if(block.timestamp < thirdStageEnd && totalSoldTokens < thirdStageTokens && weiAmount > FIFTEEN_ETHERS) {
			_tokensAmount = tokensCalculator(weiAmount, thirdStageDiscountPriceOfTokenInWei, thirdStageDiscountPriceOfTokenInWei, thirdStageDiscountCapInWei);
			return _tokensAmount;
		}
		
		if(block.timestamp < thirdStageEnd && totalSoldTokens < thirdStageTokens){
			_tokensAmount = tokensCalculator(weiAmount, thirdStagePriceOfTokenInWei, thirdStagePriceOfTokenInWei, thirdStageCapInWei);
			return _tokensAmount;
		}
		
		revert();
	}
	
	function tokensCalculator(uint256 weiAmount, uint256 currentLevelPrice, uint256 nextLevelPrice, uint256 currentLevelCap) internal returns (uint256 _tokens){
	    uint currentAmountInWei = 0;
		uint remainingAmountInWei = 0;
		uint amount = 0; 
		if(weiAmount.add(totalContributedWei) > currentLevelCap) {
		    remainingAmountInWei = (weiAmount.add(totalContributedWei)).sub(currentLevelCap);
		    currentAmountInWei = weiAmount.sub(remainingAmountInWei);
            amount = currentAmountInWei.mul(currentLevelPrice);
            amount = amount.add(remainingAmountInWei.mul(nextLevelPrice));
	    } else {
	        amount = weiAmount.mul(currentLevelPrice);
	    }
		return amount;
	}
    
	function writeOrder(address _participant, uint256 _weiAmount, uint _tokens) internal {
		if(_price == privatePreSaleCapInWei) {
			OrdersDetail[_participant].privatePresaleWEI = OrdersDetail[_participant].privatePresaleWEI.add(_weiAmount);
			OrdersDetail[_participant].privatePresaleTokens = OrdersDetail[_participant].privatePresaleTokens.add(_tokens);
		}else if (_price == totalContributedWei) {
			OrdersDetail[_participant].threeHotHoursWEI = OrdersDetail[_participant].threeHotHoursWEI.add(_weiAmount);
			OrdersDetail[_participant].threeHotHoursTokens = OrdersDetail[_participant].threeHotHoursTokens.add(_tokens);
		}else if (_price == firstStageCapInWei) {
			OrdersDetail[_participant].firstStageWEI = OrdersDetail[_participant].firstStageWEI.add(_weiAmount);
			OrdersDetail[_participant].firstStageTokens = OrdersDetail[_participant].firstStageTokens.add(_tokens);
		}else if (_price == secondStageCapInWei) {
			OrdersDetail[_participant].secondStageWEI = OrdersDetail[_participant].secondStageWEI.add(_weiAmount);
			OrdersDetail[_participant].secondStageTokens = OrdersDetail[_participant].secondStageTokens.add(_tokens);
		}else if (_price == thirdStageDiscountCapInWei) {
			OrdersDetail[_participant].thirdStageWithDiscountWEI = OrdersDetail[_participant].thirdStageWithDiscountWEI.add(_weiAmount);
			OrdersDetail[_participant].thirdStageWithDiscountTokens = OrdersDetail[_participant].thirdStageWithDiscountTokens.add(_tokens);
		}else {
			OrdersDetail[_participant].thirdStageWEI = OrdersDetail[_participant].thirdStageWEI.add(_weiAmount);
			OrdersDetail[_participant].thirdStageTokens = OrdersDetail[_participant].thirdStageTokens.add(_tokens);
		}
	}
	
	// If softcap is not reached the contributors can withdraw their ethers 
	function safeWithdraw() public {
        refund(msg.sender);
    }
    
    function refund(address _participant) internal {
        uint amountInWei = calculateContributedAmountInWei(_participant);
        
        require(amountInWei > 0);
        
        resumeContributedAmountInWei(_participant);
        
        _participant.transfer(amountInWei);
        
        emit Refunded(_participant, amountInWei);
    }
    
    function calculateContributedAmountInWei(address _participant) internal returns (uint _amountInWei) {
        _amountInWei = _amountInWei.add(OrdersDetail[_participant].privatePresaleWEI);
        _amountInWei = _amountInWei.add(OrdersDetail[_participant].threeHotHoursWEI);
        _amountInWei = _amountInWei.add(OrdersDetail[_participant].firstStageWEI);
        _amountInWei = _amountInWei.add(OrdersDetail[_participant].secondStageWEI);
        _amountInWei = _amountInWei.add(OrdersDetail[_participant].thirdStageWithDiscountWEI);
        _amountInWei = _amountInWei.add(OrdersDetail[_participant].thirdStageWEI);
        
        return _amountInWei;
    }
    
    function resumeContributedAmountInWei(address _participant) internal {
        OrdersDetail[_participant].privatePresaleWEI = 0;
        OrdersDetail[_participant].threeHotHoursWEI = 0;
        OrdersDetail[_participant].firstStageWEI = 0;
        OrdersDetail[_participant].secondStageWEI = 0;
        OrdersDetail[_participant].thirdStageWithDiscountWEI = 0;
        OrdersDetail[_participant].thirdStageWEI = 0;
    }
}
