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
	address public owner1;

	address public minter;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	function Ownable(address _owner1) public {
		require(_owner1 != msg.sender && _owner1 != address(0));
		owner = msg.sender;
		owner1 = _owner1;
	}

	modifier onlyOwner() {
		require(msg.sender == owner || msg.sender == owner1);
		_;
	}
	
	modifier onlyMinter() {
		require(msg.sender == minter);
		_;
	}
  
	modifier onlyPayloadSize(uint256 numwords) {                                       
		assert(msg.data.length == numwords * 32 + 4);
		_;
	}

	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}
	
	function setMinter(address _minterAddress) public onlyOwner {
		minter = _minterAddress;
	}
}

contract VernamCrowdSale is Ownable {
	using SafeMath for uint256;
		
	address public benecifiary;
	
	uint public startTime;
	uint public totalSoldTokens;
	uint constant FIFTEEN_ETHERS = 15 ether;
	uint constant minimumContribution = 100 finney;
	
	uint constant public privatePreSaleDuration = 3 hours;
	uint constant public privatePreSaleCapInWei = 100000000000000 wei; //1 eth == 10 000
	uint constant public privatePreSaleTokens = 100000; // 100 000 tokens
	
	uint public privatePreSaleEnd;


	uint constant public threeHotHoursDuration = 3 hours;
	uint constant public threeHotHoursCapInWei = 100000000000000 wei; //1 eth == 10 000
	uint constant public threeHotHoursTokens = 100000; // 100 000 tokens
	
	uint tokensPerEthInTHH = 1 ether / threeHotHoursCapInWei;

	uint public threeHotHoursEnd;
	
	uint constant public firstStageDuration = 24 hours;
	uint constant public firstStageCapInWei = 200000000000000 wei;    //1 eth == 5000
	uint constant public firstStageTokens = 100000; // 100 000 tokens  //maybe not constant because we must recalculate if previous have remainig

    uint tokensPerEthInFirstStage = 1 ether / firstStageCapInWei;
    
	uint public firstStageEnd;
	
	uint constant public secondStageDuration = 6 days;
	uint constant public secondStageCapInWei = 400000000000000 wei; //1 eth == 2500
	uint constant public secondStageTokens = 100000; // 100 000 tokens       //maybe not constant because we must recalculate if previous have remainig

    uint tokensPerEthInSecondStage = 1 ether / secondStageCapInWei;
    
	uint public secondStageEnd;
	
	uint constant public thirdStageDuration = 26 days;
	uint constant public thirdStageCapInWei = 600000000000000 wei;          //1 eth == 1500
	
	uint tokensPerEthInThirdStage = 1 ether / thirdStageCapInWei;
	
	uint constant public thirdStageDiscountCapInWei = 800000000000000 wei; //1 eth == 1250
	
	uint tokensPerEthInThirdDiscountStage = 1 ether / thirdStageDiscountCapInWei;
	
	uint constant public thirdStageTokens = 100000; // 100 000 tokens //maybe not constant because we must recalculate if previous have remainig
	uint public thirdStageEnd;
	
	uint constant public TokensHardCap = 500000000000000000000000000;  //500 000 000 with 18 decimals
	
	mapping(address => OrderDetail) public OrdersDetail;

	struct OrderDetail {
		uint256 privatePresaleTokens;
		uint256 privatePresaleWEI;

		uint256 threeHotHoursTokens;
		uint256 threeHotHoursWEI;

		uint256 firstStageTokens;
		uint256 firstStageWEI;

		uint256 secondStageTokens;
		uint256 secondStageWEI;

		uint256 thirdStageWithDiscountTokens;
		uint256 thirdStageWithDiscountWEI;

		uint256 thirdStageTokens;
		uint256 thirdStageWEI;
	}


	function VernamCrowdSale() public {
		benecifiary = 0xca35b7d915458ef540ade6068dfe2f44e8fa733c;
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
		require(_weiAmount > minimumContribution); // if value is smaller than most expensive stage price will count 0 tokens 
		
		//uint256 _price = getTokenPrice(_weiAmount);
		
		// We will give it _participant also to mint tokens to him
		calculateAndCreateTokens(_weiAmount);
        
        //require(totalSoldTokens > cap);
		
		// _price - we will fix it
		// writeOrder(_participant, _weiAmount, _price);
	}
	
	function calculateAndCreateTokens(uint256 weiAmount) public {
		
		// The private presale operations must be in another functions 
		/*if(block.timestamp < privatePreSaleEnd && totalSoldTokens < privatePreSaleTokens){
			return privatePreSalePrice;
		}*/
		
		// Safe math will be used 
		if(block.timestamp < threeHotHoursEnd && totalSoldTokens < threeHotHoursEnd) {
		    tokensCalculator(weiAmount, tokensPerEthInTHH, tokensPerEthInFirstStage, threeHotHoursCapInWei);
		}
		
		if(block.timestamp < firstStageEnd && totalSoldTokens < firstStageTokens) {
		    tokensCalculator(weiAmount, tokensPerEthInFirstStage, tokensPerEthInSecondStage, firstStageCapInWei);
		}
		
		if(block.timestamp < secondStageEnd && totalSoldTokens < secondStageTokens) {
			tokensCalculator(weiAmount, tokensPerEthInSecondStage, tokensPerEthInThirdStage, secondStageCapInWei);
		}
		
		if(block.timestamp < thirdStageEnd && totalSoldTokens < thirdStageTokens && weiAmount > FIFTEEN_ETHERS) {
			tokensCalculator(weiAmount, tokensPerEthInThirdDiscountStage, tokensPerEthInThirdDiscountStage, thirdStageDiscountCapInWei);
		}
		
		if(block.timestamp < thirdStageEnd && totalSoldTokens < thirdStageTokens){
		   tokensCalculator(weiAmount, tokensPerEthInThirdStage, tokensPerEthInThirdStage, thirdStageCapInWei);
		}
	}
	
	uint256 totalContributedWei;
	function tokensCalculator(uint256 weiAmount, uint256 currentLevelPrice, uint256 nextLevelPrice, uint256 currentLevelCap) internal {
	    uint currentAmountInWei = 0;
		uint remainingAmountInWei = 0;
		uint amount = 0; 
		if(weiAmount + totalContributedWei > currentLevelCap) {
		    remainingAmountInWei = (weiAmount + totalContributedWei) - currentLevelCap;
		    currentAmountInWei = weiAmount - remainingAmountInWei;

            amount = currentAmountInWei.mul(currentLevelPrice);
            amount += remainingAmountInWei.mul(nextLevelPrice);
	    } else {
	        amount = weiAmount.mul(currentLevelPrice);
	    }
		
		// Mint tokens token.mint(amount) 
		totalSoldTokens = totalSoldTokens.add(amount);
		totalContributedWei += weiAmount;
	}
    
	function writeOrder(address _participant, uint256 _weiAmount, uint _price) internal {
		if(_price == privatePreSaleCapInWei) {
			OrdersDetail[_participant].privatePresaleTokens = OrdersDetail[_participant].privatePresaleTokens.add(_weiAmount.div(_price));
			OrdersDetail[_participant].privatePresaleWEI = OrdersDetail[_participant].privatePresaleWEI.add(_weiAmount);
		}else if (_price == totalContributedWei) {
			OrdersDetail[_participant].threeHotHoursTokens = OrdersDetail[_participant].threeHotHoursTokens.add(_weiAmount.div(_price));
			OrdersDetail[_participant].threeHotHoursWEI = OrdersDetail[_participant].threeHotHoursWEI.add(_weiAmount);
		}else if (_price == firstStageCapInWei) {
			OrdersDetail[_participant].firstStageTokens = OrdersDetail[_participant].firstStageTokens.add(_weiAmount.div(_price));
			OrdersDetail[_participant].firstStageWEI = OrdersDetail[_participant].firstStageWEI.add(_weiAmount);
		}else if (_price == secondStageCapInWei) {
			OrdersDetail[_participant].secondStageTokens = OrdersDetail[_participant].secondStageTokens.add(_weiAmount.div(_price));
			OrdersDetail[_participant].secondStageWEI = OrdersDetail[_participant].secondStageWEI.add(_weiAmount);
		}else if (_price == thirdStageDiscountCapInWei) {
			OrdersDetail[_participant].thirdStageWithDiscountTokens = OrdersDetail[_participant].thirdStageWithDiscountTokens.add(_weiAmount.div(_price));
			OrdersDetail[_participant].thirdStageWithDiscountWEI = OrdersDetail[_participant].thirdStageWithDiscountWEI.add(_weiAmount);
		}else {
			OrdersDetail[_participant].thirdStageTokens = OrdersDetail[_participant].thirdStageTokens.add(_weiAmount.div(_price));
			OrdersDetail[_participant].thirdStageWEI = OrdersDetail[_participant].thirdStageWEI.add(_weiAmount);
		}
	} 
}
