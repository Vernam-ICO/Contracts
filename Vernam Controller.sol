contract OwnableController {
	address public owner;
	address public KYCTeam;
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	constructor() public {
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}
	
	modifier onlyKYCTeam() {
		require(msg.sender == KYCTeam);
		_;
	}
	
	function setKYCTeam(address _KYCTeam) public onlyOwner {
		KYCTeam = _KYCTeam;
	}

	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}
}
contract Controller is OwnableController {
    
    VernamCrowdSale public vernamCrowdSale;
	VernamCrowdSaleToken public vernamCrowdsaleToken;
	VernamToken public vernamToken;
	
	mapping(address => bool) public isParticipantApproved;
    
    event Refunded(address _to, uint amountInWei);
	event Convert(address indexed participant, uint tokens);
    
    function Controller(address _crowdsaleAddress, address _vernamCrowdSaleToken, address _vernamToken) public {
        vernamCrowdSale = VernamCrowdSale(_crowdsaleAddress);
		vernamCrowdsaleToken = VernamCrowdSaleToken(_vernamCrowdSaleToken);
		vernamToken = VernamToken(_vernamToken);
    }
    
    function releaseThreeHotHourTokens() public {
        vernamCrowdSale.releaseThreeHotHourTokens(msg.sender);
    }
	
	function convertYourTokens() public {
		convertTokens(msg.sender);
	}
	
	function convertTokens(address _participant) public {
	    bool isApproved = vernamCrowdsaleToken.isKYCApproved(_participant);
		if(isApproved == false && isParticipantApproved[_participant] == true){
			vernamCrowdsaleToken.approveKYC(_participant);
			isApproved = vernamCrowdsaleToken.isKYCApproved(_participant);
		}
	    
	    require(isApproved == true);
	    
		uint256 tokens = vernamCrowdsaleToken.balanceOf(_participant);
		
		require(tokens > 0);
		vernamCrowdsaleToken.burn(_participant, tokens);
		vernamToken.transfer(_participant, tokens);
		
		emit Convert(_participant, tokens);
	}
	
	function approveKYC(address _participant) public onlyKYCTeam returns(bool _success) {
	    vernamCrowdsaleToken.approveKYC(_participant);
		isParticipantApproved[_participant] = vernamCrowdsaleToken.isKYCApproved(_participant);
	    return isParticipantApproved[_participant];
	}
}