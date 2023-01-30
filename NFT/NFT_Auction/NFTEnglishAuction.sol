// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**IERC721 interfaces
 * @dev interfaces to interact with NFT product properties
 * @dev safeTransferFrom function for transfer NFT product to highestBidder after bid ended
 * @dev transferFrom function to transfer token to Auction address
 * @dev ownerOf function to get recent owner of NFT(product)
 * @dev getApproved function to get the approve address
 */
interface IERC721 {
    function safeTransferFrom(address from, address to, uint tokenId) external;

    function transferFrom(address, address, uint) external;

    function tokenURI(
        uint _tokenId
    ) external view returns (string memory tokenURI);

    function ownerOf(uint tokenId) external view returns (address owner);

    function getApproved(uint tokenId) external view returns (address operator);
}

contract NFTEnglishAuction {
    //events
    event Started(bytes32 _productId, uint _bidinterval);
    event Bid(address indexed sender, uint amount);
    event Withdraw(address indexed bidder, uint amount);
    event BidSuccesfullyEnded(address winner, uint amount);
    event BidEndedWithoutPerticipating(address winner, uint _nftId);
    event ProductAdded(bytes32 _productId);

    //Auction's variables
    address payable public immutable Auctioneer;
    uint256 private totalFee;
    uint256 private immutable minimumFee;

    //product info struct
    struct prductBidInfo {
        IERC721 productNftAddress;
        address productOwner;
        string productURI;
        uint nftId;
        uint bidEndedAt;
        address highestBidder;
        uint highestBid;
        bool IsStarted;
    }

    //variable to operate bid
    bytes32[] private Products;
    mapping(bytes32 => prductBidInfo) public Product;
    mapping(bytes32 => mapping(address => uint)) private bids;

    constructor(uint _minimumFee) {
        Auctioneer = payable(msg.sender);
        minimumFee = _minimumFee;
    }

    //modifier to restricted function calling authority

    modifier _onlyApprovedOrOwner(IERC721 _nftContract, uint _nftId) {
        address ProductOwner = _nftContract.ownerOf(_nftId);
        address approvedAddress = _nftContract.getApproved(_nftId);
        require(
            msg.sender.code.length == 0,
            "No contract can Addproduct and start bid"
        );
        require(
            msg.sender == ProductOwner || msg.sender == approvedAddress,
            "only Product owner or approved spender can start the auction"
        );
        _;
    }

    modifier _onlyOwnerOrHighestBidder(bytes32 _productId) {
        address productOwner = Product[_productId].productOwner;
        address productHighestBidder = Product[_productId].highestBidder;
        require(
            msg.sender == productOwner || msg.sender == productHighestBidder,
            "invalid END function caller"
        );
        _;
    }

    modifier _onlyAuctioner() {
        require(msg.sender == Auctioneer, "Caller not Auctioner");
        require(msg.sender.code.length == 0);
        _;
    }

    /**
     * AddProduct function to add NFT product to this Auction
     * @param _nftAddress product NFT address
     * @param _nftId product Nft Id
     * @dev only Approved Address and Owner of NFT(product) has calling authority of this function
     */
    function addProduct(
        address _nftAddress,
        uint _nftId
    )
        external
        payable
        _onlyApprovedOrOwner(IERC721(_nftAddress), _nftId)
        returns (bytes32)
    {
        //generating product id hash by keccak256 hashing algorithm
        bytes32 productid = keccak256(abi.encodePacked(_nftAddress, _nftId));
        require(
            msg.value >= minimumFee,
            "Insuficient transaction to AddProduct"
        ); //have to pay minimum fee to add product
        totalFee += msg.value; // fee is added to totalfee
        Products.push(productid); // productId push in Products Array
        IERC721 nft = IERC721(_nftAddress); // nft address

        Product[productid].productNftAddress = nft; // adding nft address to Product
        Product[productid].nftId = _nftId; // adding nftId to Product
        Product[productid].IsStarted = false;
        //adding NFT URI and Owner
        Product[productid].productURI = nft.tokenURI(_nftId);
        Product[productid].productOwner = nft.ownerOf(_nftId);
        emit ProductAdded(productid);
        //checking msg.sender is owner of NFT or getApproved
        return productid;
    }

    /**
     * Start function to Auction start
     * @param _productId start the specific product Auction by its hashId
     * @param _bidingdelay auctionperiod
     * @param _startingBid  Auction started Bid(Base price) in ETH formste
     * @dev only Approved Address and Owner of NFT(product) has calling authority of this function
     */
    function start(
        bytes32 _productId,
        uint _bidingdelay,
        uint _startingBid
    )
        external
        _onlyApprovedOrOwner(
            Product[_productId].productNftAddress,
            Product[_productId].nftId
        )
        returns (bool)
    {
        require(!Product[_productId].IsStarted, "already Started");
        IERC721 _nft = Product[_productId].productNftAddress; //product NFt address
        uint _nftId = Product[_productId].nftId; //product nftid
        address ApprovedAddress = _nft.getApproved(_nftId); //product approved address
        require(ApprovedAddress == address(this)); // product(NFT) should be approved by this address
        _nft.transferFrom(msg.sender, address(this), _nftId); // NFT(prodcut) transfer to this contract

        uint _dayToSec = 3600 * 24 * _bidingdelay; //day convert to sec
        Product[_productId].highestBid = _startingBid; // Assign base bid
        Product[_productId].IsStarted = true; // start true
        Product[_productId].bidEndedAt = block.timestamp + _dayToSec; // set ended Auction period
        emit Started(_productId, _dayToSec); //emite the event of Started Auction of this product(productid)
        return true; //return true if all goes well
    }

    /**
     * bid a specific product
     * @param _productId specify the product by productid
     * @dev Any EOA address can perticipate the Auction period
     * @dev no contract can perticipate the auction
     */
    function bid(bytes32 _productId) external payable returns (bool) {
        require(msg.sender.code.length == 0); //only EOA can bid
        require(Product[_productId].IsStarted, "Sorry Bid not  started yet"); // Any EOA can perticipte if auction started for this product
        require(
            block.timestamp < Product[_productId].bidEndedAt,
            "Sorry Bid Ended"
        ); //can bid only auction period
        require(msg.value > Product[_productId].highestBid, "value < highest"); // only higest bidding proposal can bid

        bids[_productId][msg.sender] = msg.value; // add the bidder info in bids mapping
        Product[_productId].highestBidder = msg.sender; // set higestbidder of this product
        Product[_productId].highestBid = msg.value; // set the highestbid to this product

        emit Bid(msg.sender, msg.value); // emit the Bid events with bidder address and bid value
        return true; //return true if all goes well
    }

    /**
     * withdraw function for lower bidder to withdraw their money after bid ended
     * @param _productId hashId of product which where they bid
     * @dev only lower bidder after bid ended can withdraw the value
     */
    function withdraw(bytes32 _productId) external returns (bool) {
        require(
            block.timestamp > Product[_productId].bidEndedAt &&
                !Product[_productId].IsStarted,
            "Can only withdraw after Bid ended"
        ); // can only withdraw after ended the bid
        require(
            bids[_productId][msg.sender] > 0,
            "sorry You dont have any balances"
        );
        uint bal = bids[_productId][msg.sender]; //bidder balance;
        bids[_productId][msg.sender] = 0; //set 0 to the bidder address
        (bool sent, ) = payable(msg.sender).call{value: bal}(""); //transfer the value to bidder by call function
        require(sent, "Failed to withdraw Ether");
        emit Withdraw(msg.sender, bal); //emit Withdraw with bidder address and bid value
        return true;
    }

    /**
     * BidEnd function to conclution Auction result
     * @param _productId  calling BidEnd  to specific product
     * @dev only Product owner and HigestBidder (winner) can call the function
     * @dev if anyone bid then contract transfer the product(NFT) to the highestBidder
     * @dev if None Bid then contract transfer the Product(NFT) to the previous Owner who add the product
     * @dev reinitialize the productInfo  to the Product mapping
     * @dev adv of higest bidder dont need to AddProduct again in this Auction contract contract will save the productInfo
     */
    function bidEnd(
        bytes32 _productId
    ) external _onlyOwnerOrHighestBidder(_productId) returns (bool) {
        require(Product[_productId].IsStarted, "Sorry Bid not  started yet"); //Auction of this product should start first

        require(
            block.timestamp >= Product[_productId].bidEndedAt,
            "Sorry Bid Ended already"
        ); // Auction period should over

        Product[_productId].IsStarted = false; // set isStarted to false (stop Bid)
        IERC721 nft = Product[_productId].productNftAddress; //product(NFT) contract address
        uint _nftId = Product[_productId].nftId; // product(NFT)  Id by the contract
        address HighestBidder = Product[_productId].highestBidder; // higest Bidder
        uint HigestBid = Product[_productId].highestBid; //HigestBid price
        address productOwner = Product[_productId].productOwner; //previous Product(NFT) owner
        if (HighestBidder != address(0)) {
            //if higestBidder exist
            totalFee += (HigestBid) / 100; //1% of HighestBid price take as fee to this contract
            uint amountSentToOwner = (HigestBid * 99) / 100; //rest of the 99% send to the previous Owner address
            nft.safeTransferFrom(address(this), HighestBidder, _nftId); // safely transfer product(NfT) to the HigestBidder Address
            (bool sent, ) = productOwner.call{value: amountSentToOwner}(""); //sending 99% higest bid price to the previousOwner
            require(sent, "Failed to send Ether");
            emit BidSuccesfullyEnded(HighestBidder, HigestBid); //succesfull bid events will emit
        } else {
            //if highestBidder doesnt exist transfer the product(NFT) to the previous owner
            nft.transferFrom(
                address(this),
                Product[_productId].productOwner,
                _nftId
            );
            emit BidEndedWithoutPerticipating(
                Product[_productId].productOwner,
                _nftId
            ); //unseccessfull events will emit
        }

        //reintializing Product mapping value
        Product[_productId].productOwner = nft.ownerOf(_nftId);
        Product[_productId].bidEndedAt = 0;
        Product[_productId].highestBidder = address(0);
        return true; //return true if all goes well
    }

    /**getter function of private variables
     * @dev getProducts of Products array by index
     * @dev NumberOfProducts to get total listing product
     * @dev getBids for bidder to get their bal by product Id
     * @dev contractBalance to get contract balance
     * @dev getCollectedfee to auctioner can check total collected fee
     * @dev AuctionerWithdraw to auctioner can withdraw the collected fee
     */
    function getProducts(
        uint _productIteration
    ) external view returns (bytes32) {
        return Products[_productIteration];
    }

    function numberOfProducts() external view returns (uint) {
        return Products.length;
    }

    function getBids(
        bytes32 _productId,
        address bidderAddress
    ) external view returns (uint balance) {
        return bids[_productId][bidderAddress];
    }

    function contractBalance() external view returns (uint) {
        return (address(this)).balance;
    }

    function getCollectedFee() external view _onlyAuctioner returns (uint) {
        return totalFee;
    }

    function auctionerWithdraw(
        uint _amount
    ) external _onlyAuctioner returns (bool) {
        require(_amount <= totalFee, "Insuficient collected fee to withdraw");
        totalFee -= _amount;
        (bool sent, ) = Auctioneer.call{value: _amount}("");
        return sent;
    }
}
