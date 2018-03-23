contract Controller {
    
    VernamCrowdSale public vernamCrowdSale;
	VernamCrowdsaleToken public vernamCrowdsaleToken;
	VernamToken public vernamToken

    
    event Refunded(address _to, uint amountInWei);
	event Convert(address indexed participant, uint tokens);
    
    function Controller(address _crowdsaleAddress, address _vernamCrowdSaleToken, address _vernamToken) public {
        vernamCrowdSale = VernamCrowdSale(_crowdsaleAddress);
		vernamCrowdsaleToken = VernamCrowdsaleToken(_vernamCrowdSaleToken);
		vernamToken = VernamToken(_vernamToken);
    }
    
    function safeWithdraw() public {
        refund(msg.sender);
    }
    
    function refund(address _to) internal {
        uint amountInWei = vernamCrowdSale.getContributedAmountInWei(_to);

        require(amountInWei > 0);
        
        vernamCrowdSale.setContributedAmountInWei(_to);
        _to.transfer(amountInWei);
        
        emit Refunded(_to, amountInWei);
    }
    
    function releaseThreeHotHourTokens() public {
        vernamCrowdSale.releaseThreeHotHourTokens(msg.sender);
    }
	
	function convertTokens(address _participant) public {
		uint256 tokens = vernamCrowdsaleToken.balanceOf(_participant);
		require(tokens > 0);
		require(vernamCrowdsaleToken.burn(_participant,tokens) && vernamToken.transfer(_participant,tokens));
		Convert(_participant,tokens);
	}
}
