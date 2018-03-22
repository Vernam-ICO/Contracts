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
	
	mapping(address => uint256) public privatePreSaleBalances;
	mapping(address => bool) public isParticipatePrivate;
	mapping(address => uint256) public weiBalances;
	
	uint256 constant public minimumContribution = 25000000000000000000 wei;
	uint256 constant public privatePreSalePrice = 85000000000000 wei;
	uint256 constant public maximumCOntributionWEI = 4250000000000000000000 wei;
	uint256 constant public totalTokensForSold = 50000000000000000000000000;
	uint256 public privatePreSaleSoldTokens;
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
		require(_value >= minimumContribution);
		require(maximumCOntributionWEI >= totalInvested);
		beneficiary.transfer(_value);
		weiBalances[_participant] = weiBalances[_participant].add(_value);
		totalInvested = totalInvested.add(_value);
		uint256 tokens = ((_value).mul(1 ether)).div(privatePreSalePrice);
		privatePreSaleSoldTokens = privatePreSaleSoldTokens.add(tokens);
		privatePreSaleBalances[_participant] = privatePreSaleBalances[_participant].add(tokens);
		isParticipatePrivate[_participant] = true;
		vernamCrowdsaleToken.mintToken(_participant, tokens);
	}
	
	function getPrivatePreSaleBalance(address _participant) public view returns(uint256) {
		return privatePreSaleBalances[_participant];
	}	

	function getIsParticipatePrivate(address _participant) public view returns(bool) {
		return isParticipatePrivate[_participant];
	}	

	function getWeiBalance(address _participant) public view returns(uint256) {
		return weiBalances[_participant];
	}
} 