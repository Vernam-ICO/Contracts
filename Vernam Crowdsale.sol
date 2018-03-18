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

	uint constant public threeHotHoursDuration = 3 hours;
	uint constant public threeHotHoursPrice = 100000000000000 wei; //1 eth == 10 000
	uint constant public threeHotHoursTokens = 100000; // 100 000 tokens

	uint public threeHotHoursEnd;
	
	uint constant public firstStageDuration = 24 hours;
	uint constant public firstStagePrice = 200000000000000 wei;    //1 eth == 5000
	uint constant public firstStageTokens = 100000; // 100 000 tokens  //maybe not constant because we must recalculate if previous have remainig

	uint public firstStageEnd;
	
	uint constant public secondStageDuration = 6 days;
	uint constant public secondStagePrice = 400000000000000 wei; //1 eth == 2500
	uint constant public secondStageTokens = 100000; // 100 000 tokens       //maybe not constant because we must recalculate if previous have remainig

	uint public secondStageEnd;
	
	uint constant public thirdStageDuration = 26 days;
	uint constant public thirdStagePrice = 600000000000000 wei;          //1 eth == 1500
	uint constant public thirdStageDiscountPrice = 800000000000000 wei; //1 eth == 1250
	uint constant public thirdStageTokens = 100000; // 100 000 tokens //maybe not constant because we must recalculate if previous have remainig
	uint public thirdStageEnd;
	
	uint constant public TokensHardCap = 500000000000000000000000000;  //500 000 000 with 18 decimals
	
	mapping(address => OrderDetail) public OrdersDetail;

	struct OrderDetail {
		uint256 privatePresale;
		uint256 privatePresaleWEI;

		uint256 threeHotHours;
		uint256 threeHotHoursWEI;

		uint256 firstStage;
		uint256 firstStageWEI;

		uint256 secondStage;
		uint256 secondStageWEI;

		uint256 thirdStageWithDiscount;
		uint256 thirdStageWithDiscountWEI;

		uint256 thirdStage;
		uint256 thirdStageWEI;
	}


	function VernamCrowdSale() public {
		benecifiary = 0xca35b7d915458ef540ade6068dfe2f44e8fa733c;
	}
	
	function activateCrowdSale() public onlyOwner {
		startTime = block.timestamp;
		threeHotHoursEnd = startTime.add(threeHotHoursDuration);
		firstStageEnd = threeHotHoursEnd.add(firstStageDuration);
		secondStageEnd = firstStageEnd.add(secondStageDuration);
		thirdStageEnd = secondStageEnd.add(thirdStageDuration);
	}
	
	function() public payable {
		buyTokens(msg.sender,msg.value);
	}
	
	function buyTokens(address _participant, uint256 _weiAmount) public payable returns(bool) {
		OrdersDetail[_participant].privatePresaleWEI = OrdersDetail[_participant].privatePresaleWEI.add(_weiAmount);
	}
	
    function getTokenPrice(uint256 _weiAmount) public view returns (uint256) {
		if(block.timestamp < threeHotHoursEnd && totalSoldTokens < threeHotHoursTokens){
			return threeHotHoursPrice;
		}
		
		if(block.timestamp < firstStageEnd && totalSoldTokens < firstStageTokens){
			return firstStagePrice;
		}
		
		if(block.timestamp < secondStageEnd && totalSoldTokens < secondStageTokens){
			return secondStagePrice;
		}
		
		if(block.timestamp < thirdStageEnd && totalSoldTokens < thirdStageTokens && _weiAmount > FIFTEEN_ETHERS){
			return thirdStageDiscountPrice;
		}
		
		return thirdStagePrice;
	}
}
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	