contract Controller {
    
    VernamCrowdSale public vernamCrowdSale;
	VernamCrowdSaleToken public vernamCrowdsaleToken;
	VernamToken public vernamToken;
    
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
	
	function convertTokens(address _participant) public {
	    bool isApproved = vernamCrowdsaleToken.isKYCApproved(_participant);
	    
	    require(isApproved == true);
	    
		uint256 tokens = vernamCrowdsaleToken.balanceOf(_participant);
		
		require(tokens > 0);
		require(vernamCrowdsaleToken.burn(_participant, tokens));
		require(vernamToken.transfer(_participant, tokens));
		
		emit Convert(_participant, tokens);
	}
	
	function approveKYC(address _participant) public returns(bool _success) {
	    vernamCrowdsaleToken.approveKYC(_participant);
	    
	    return true;
	}
}