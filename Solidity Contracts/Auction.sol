// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionSystem {
    address Owner;
    struct Product {
        string name;
        string ProductInformation;
        //uint ProductId;
        uint256 minPrice;
        bool AuctionedProduct;
    }
    struct Bidder{
        string name;
        bool ValidBidder;
        uint CurrrentBid;
        uint TotalBid;
    }
    //TODO: update currentBid and TotalBid
    //TODO: update Highest Bidder
    struct Auction{
        address HighestBidder;
        uint currentHighestBid;
        uint ProductToBeAuctioned;
        bool AuctionStart;
        bool AuctionEnd;
        uint AuctionStartTime;
        uint AuctionEndTime;
    }

    Auction public Auction1;

    mapping(address => Bidder) BuyerFetch;
    address[] BuyerAddressList;

    Product[] ProductFetch;

    constructor() {
        Owner = msg.sender;
    }

    modifier OnlyOwner() {
        require(msg.sender == Owner, "Owner access only.");
        _;
    }

    function addProduct(
        string memory _name,
        string memory _ProductInformation,
        uint256 _minPrice
    ) external 
    OnlyOwner 
    {
        ProductFetch.push(Product(_name, _ProductInformation, _minPrice,false));
    }

    function setBuyer(string memory _name) external {
        require(msg.sender != Owner,"Owner cannot register");
        require(
            BuyerFetch[msg.sender].ValidBidder == false,
            "Bidder cannot register themselves again."
        );
        BuyerFetch[msg.sender].ValidBidder = true;
        BuyerFetch[msg.sender].name = _name;
        BuyerAddressList.push(msg.sender);        
    }

    function StartAuction(uint _productId) external OnlyOwner{
        require(Auction1.AuctionStart == false,"Auction already in Progress.");
        require(_productId > 0 && _productId <= ProductFetch.length,"Enter Valid ProductId.");
        Auction1.ProductToBeAuctioned = _productId; // saves index of the product to be auctioned
        Auction1.AuctionStartTime = block.timestamp;
        Auction1.AuctionEndTime = Auction1.AuctionStartTime + 120;
        Auction1.currentHighestBid = ProductFetch[--_productId].minPrice;

        Auction1.AuctionStart = true;

        // bool AuctionStart;
        // uint AuctionStartTime;
        // uint AuctionEndTime;
    }
    function Bid() external payable{
        require(Auction1.AuctionStart,"Auction not Started");
        require(Auction1.AuctionEnd==false,"Auction Finished");
        if(block.timestamp < Auction1.AuctionEndTime){
            require(BuyerFetch[msg.sender].ValidBidder,"Not a valid Bidder.");
            require(msg.value >= Auction1.currentHighestBid,"Bid More.");
            Auction1.currentHighestBid = msg.value;
            BuyerFetch[msg.sender].CurrrentBid = msg.value;
            BuyerFetch[msg.sender].TotalBid += msg.value;
            Auction1.HighestBidder = msg.sender;
        if(block.timestamp >= Auction1.AuctionEndTime - 60){
            Auction1.AuctionEndTime = block.timestamp + 20;
        }
        }
        else{
            uint amount = msg.value;
            payable(msg.sender).transfer(amount);
            // to send back the last irrelevent amount.
            Auction1.AuctionStart = false;
            Auction1.AuctionEnd = true;
            RevertandPayOwner();
        }
        
    }
    function GetCurrentHighestBidder() public view returns(Bidder memory){
        require(Auction1.AuctionStart,"Auction not Started");
        return(BuyerFetch[Auction1.HighestBidder]);
    } 
    function GetCurrentHighestBid() external view returns(uint){
        require(Auction1.AuctionStart,"Auction not Started");
        return Auction1.currentHighestBid;
    }
    function RevertandPayOwner() internal{
        Auction1.AuctionStart = false;
        for(uint i=0; i < BuyerAddressList.length;i++){
            uint amount = BuyerFetch[BuyerAddressList[i]].TotalBid;
            if(BuyerAddressList[i] == Auction1.HighestBidder){
                amount = amount - BuyerFetch[BuyerAddressList[i]].CurrrentBid;
                payable(BuyerAddressList[i]).transfer(amount);
                payable(Owner).transfer(BuyerFetch[BuyerAddressList[i]].CurrrentBid);
            }
            else{
                payable(BuyerAddressList[i]).transfer(amount);
            }
        }
    }
    function RevertandPayOwnerAccess() external OnlyOwner{
        RevertandPayOwner();
    }
    function View_Winner() external view returns(Bidder memory){
        require(Auction1.AuctionEnd,"Auction has not Ended.");
        return BuyerFetch[Auction1.HighestBidder];
    }
}
