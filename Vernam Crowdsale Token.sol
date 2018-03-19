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

contract CrowdsaleVernam {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Ownable {
	address public owner;
	address public owner1;

	address public minter;
	address public burner;

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
	
	modifier onlyBurner() {
		require(msg.sender == burner);
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
	
	function setBurner(address _burnerAddress) public onlyOwner {
		burner = _burnerAddress;
	}
}
/*
contract KYCControl is Ownable {
	
	VernamToken crowdsaleToken;
	event IsKYCApprovedLog(address _user, bool isApproved);

	mapping(address => bool) isKYCApproved; // must check the array does everething is false
	
	function KYCControl(address _token){
		crowdsaleToken = VernamToken(_token);
	}
	
	function isKYCApprove(address _who) view public returns (bool _isAprroved){
		return isKYCApproved[_who];
	}

	function KYCApprove(address _userAddress) onlyOwner public {
		isKYCApproved[_userAddress] = true;
		IsKYCApprovedLog(_userAddress, true);
	}
}*/

contract VernamCrowdSaleToken is Ownable,CrowdsaleVernam {
	using SafeMath for uint256;
	
	/* Public variables of the token */
	string public name;
	string public symbol;
	uint8 public decimals;
	uint256 public _totalSupply;
	
	/*Private Variables*/
	uint256 constant POW = 10 ** 18;
	uint256 _circulatingSupply;
	
	/* This creates an array with all balances */
	mapping (address => uint256) public balances;
	mapping (address => uint256) public threeHotHoursBalance;
		
	// This notifies clients about the amount burnt
	event Burn(address indexed from, uint256 value);


	/* Initializes contract with initial supply tokens to the creator of the contract */
	function VernamCrowdSaleToken() public {
		name = "Vernam Crowdsale Token";                                   	// Set the name for display purposes
		symbol = "VCT";                               				// Set the symbol for display purposes
		decimals = 18;                            					// Amount of decimals for display purposes
		_totalSupply = SafeMath.mul(1000000000,POW);     //1 BLN TOKENS WITH 18 Decimals 					// Update total supply
		_circulatingSupply = 0;
	}

	event Mint(address indexed _participant, uint256 value);
	function mintToken(address _participant, uint256 _mintedAmount) public onlyMinter returns (bool _success) {
		require(_mintedAmount > 0);
		require(_circulatingSupply.add(_mintedAmount) <= _totalSupply);
		
        balances[_participant] =  balances[_participant].add(_mintedAmount);
        _circulatingSupply = _circulatingSupply.add(_mintedAmount);
		emit Transfer(0, this, _mintedAmount);
        emit Transfer(this, _participant, _mintedAmount);
		
		emit Mint(_participant, _mintedAmount);
		return true;
    }
	
	function burn(address _participant, uint256 _value) public onlyBurner returns (bool _success) {
        require(balances[_participant] >= _value);   							// Check if the sender has enough
        balances[_participant] = balances[_participant].sub(_value);              // Subtract from the sender
		_circulatingSupply = _circulatingSupply.sub(_value);
        _totalSupply = _totalSupply.sub(_value);                      							// Updates totalSupply
		emit Transfer(_participant, 0, _value);
        emit Burn(_participant, _value);
        return true;
    }
  
	function totalSupply() public view returns (uint256) {
		return _totalSupply;
	}
	
	function circulatingSupply() public view returns (uint256) {
		return _circulatingSupply;
	}
	
	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}

}
