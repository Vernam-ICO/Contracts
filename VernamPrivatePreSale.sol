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

contract VernamPrivatePreSale {
	using SafeMath for uint256;

	VernamCrowdSaleToken public vernamCrowdsaleToken;
	
	mapping(address => uint256) public privatePreSaleTokenBalances;
	mapping(address => bool) public isParticipatePrivate; // maybe we do not need this 
	mapping(address => uint256) public weiBalances;
	
	uint256 constant public minimumContributionWeiByOneInvestor = 25000000000000000000 wei;
	uint256 constant public privatePreSalePrice = 85000000000000 wei;
	uint256 constant public totalSupplyInWei = 4250000000000000000000 wei;
	uint256 constant public totalTokensForSold = 50000000000000000000000000; // maybe we do not need this 
	uint256 public privatePreSaleSoldTokens; // maybe we do not need this
	uint256 public totalInvested;
	
	address public beneficiary;
	
	function VernamPrivatePreSale(address _beneficiary, address vrn) public {
		beneficiary = _beneficiary;
		vernamCrowdsaleToken = VernamCrowdSaleToken(vrn);
	}
	
	function() public payable {
		buyPreSale(msg.sender, msg.value);
	}
	
	function buyPreSale(address _participant, uint256 _value) payable public {
		require(_value >= minimumContributionWeiByOneInvestor);
		require(totalSupplyInWei >= totalInvested.add(_value));
		
		beneficiary.transfer(_value);
		
		weiBalances[_participant] = weiBalances[_participant].add(_value);
		
		totalInvested = totalInvested.add(_value);
		
		uint256 tokens = ((_value).mul(1 ether)).div(privatePreSalePrice);
		
		privatePreSaleSoldTokens = privatePreSaleSoldTokens.add(tokens);
		privatePreSaleTokenBalances[_participant] = privatePreSaleTokenBalances[_participant].add(tokens);
		
		isParticipatePrivate[_participant] = true;
		
		vernamCrowdsaleToken.mintToken(_participant, tokens);
	}
	
	function getPrivatePreSaleTokenBalance(address _participant) public view returns(uint256) {
		return privatePreSaleTokenBalances[_participant];
	}	
	
	// maybe we do not need this
	function getIsParticipatePrivate(address _participant) public view returns(bool) {
		return isParticipatePrivate[_participant];
	}	

	function getWeiBalance(address _participant) public view returns(uint256) {
		return weiBalances[_participant];
	}
} 