pragma solidity ^0.4.21;

contract VernamWhiteListDeposit {
	
	address public benecifiary;
	mapping (address => bool) public isWhiteList;
	uint256 public constant depositAmount = 10000000000000000 wei;   // 0.01 ETH
	
	function VernamWhiteListDeposit(address _benecifiary) public {
		benecifiary = _benecifiary;
	}
	
	event WhiteListSuccess(address indexed _whiteListParticipant, uint256 _amount);
	function() public payable {
		require(msg.value == depositAmount);
		require(!isWhiteList[msg.sender]);
		benecifiary.transfer(msg.value);
		isWhiteList[msg.sender] = true;
		emit WhiteListSuccess(msg.sender, msg.value);
	}
}