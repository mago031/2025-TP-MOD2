// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Auction Contract
 * @dev Implements a secure and robust auction system.
 */
contract Auction {
    // Struct to represent a bid
    struct Bid {
        address bidder;
        uint amount;
    }

    // Variables
    address public owner;
    string public item;
    uint public startTime;
    uint public endTime;
    uint public highestBid;
    address public highestBidder;
    uint public commissionPercentage = 2;
    bool public isFinalized;

    mapping(address => uint) public refunds;
    Bid[] public bids;

    // Events
    event NewBid(address indexed bidder, uint amount);
    event AuctionFinalized(address winner, uint amount);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    modifier auctionActive() {
        require(block.timestamp >= startTime && block.timestamp <= endTime, "Auction is not active.");
        _;
    }

    modifier auctionEnded() {
        require(block.timestamp > endTime, "Auction has not ended.");
        _;
    }

    /**
     * @dev Constructor to initialize the auction.
     * @param _item Name of the item being auctioned.
     * @param _duration Duration of the auction in seconds.
     */
    constructor(string memory _item, uint _duration) {
        owner = msg.sender;
        item = _item;
        startTime = block.timestamp;
        endTime = block.timestamp + _duration;
        isFinalized = false;
    }

    /**
     * @dev Place a new bid. The bid must be at least 5% higher than the current highest bid.
     */
    function placeBid() public payable auctionActive {
    require(msg.value > highestBid + (highestBid / 20), "Bid must be at least 5% higher than the current highest bid.");

    // Refund the previous highest bidder
    if (highestBid > 0) {
        refunds[highestBidder] += highestBid;
    }

    // Record the new highest bid
    highestBid = msg.value;
    highestBidder = msg.sender;

    bids.push(Bid({bidder: msg.sender, amount: msg.value}));

    // Extend the auction only if it is within the last 10 minutes
    if (block.timestamp > endTime - 10 minutes) {
        uint remainingTime = endTime - block.timestamp;
        if (remainingTime < 10 minutes) {
            endTime += 10 minutes; // Extend the time once per cycle
        }
    }

    emit NewBid(msg.sender, msg.value);
}


    /**
     * @dev Get the list of all bids.
     */
    function getBids() public view returns (Bid[] memory) {
        return bids;
    }

    /**
     * @dev Finalize the auction. Only callable after the auction has ended.
     */
    function finalizeAuction() public onlyOwner auctionEnded {
        require(!isFinalized, "Auction has already been finalized.");

        // Transfer the highest bid to the owner, minus the commission
        uint commission = (highestBid * commissionPercentage) / 100;
        uint amountToOwner = highestBid - commission;

        payable(owner).transfer(amountToOwner);
        isFinalized = true;

        emit AuctionFinalized(highestBidder, highestBid);
    }

    /**
     * @dev Claim refunds for non-winning bids.
     */
    function claimRefund() public {
        uint refundAmount = refunds[msg.sender];
        require(refundAmount > 0, "No refund available.");

        refunds[msg.sender] = 0;
        payable(msg.sender).transfer(refundAmount);
    }

    /**
     * @dev Get auction details.
     */
    function getAuctionDetails() public view returns (
        string memory,
        uint,
        uint,
        uint,
        address,
        bool
    ) {
        return (
            item,
            startTime,
            endTime,
            highestBid,
            highestBidder,
            isFinalized
        );
    }
}
