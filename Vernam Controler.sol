contract Controller {
    
    VernamCrowdSale vernamCrowdSale;
    
    event Refunded(address _to, uint amountInWei);
    
    function Controller(address _crowdsaleAddress) public {
        vernamCrowdSale = VernamCrowdSale(_crowdsaleAddress);
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
}
