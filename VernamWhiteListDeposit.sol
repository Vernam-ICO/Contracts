contract VernamWhiteListDeposit {
	
	address public benecifiary;
	mapping (address => bool) public isWhiteList;
	uint256 public constant depositAmount;
	
	function VernamWhiteListDeposit(address _benecifiary) public {
		benecifiary = _benecifiary;
		depositAmount = 0.01 * 1 ethers;
	}
	
	function() public paybale {
		require(msg.value == depositAmount);
		require(!isWhiteList[msg.sender]);
		benecifiary.transfer(msg.value);
		isWhiteList[msg.sender] = true;
	}
}