// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice Raised when an invalid auction kind was provided.
 *
 * @param provided The auction kind that was provided.
 */
error Auction__InvalidAuctionKind(uint256 provided);

/**
 * @notice Raised when an invalid auction length was provided.
 *
 * @param provided  The auction length that was provided.
 * @param min       The minimum length that is required.
 */
error Auction__InvalidAuctionLength(uint256 provided, uint256 min);

/**
 * @notice Raised when a feature that requires the auction to be active was
 * accessed while it is inactive.
 */
error Auction__AuctionNotStarted();

/**
 * @notice Raised when a feature that requires the auction to be inactive was
 * accessed while it is active.
 */
error Auction__AuctionActive();

/**
 * @notice Raised when a feature that requires the auction to be active was
 * accessed after it finished.
 */
error Auction__AuctionFinished();

/**
 * @notice Raised when an account does not have a Proof of Identity NFT.
 */
error Auction__NoIdentityNFT();

/**
 * @notice Raised when an account is suspended.
 */
error Auction__Suspended();

/**
 * @notice Raised when an attribute has expired.
 *
 * @param attribute The name of the required attribute.
 * @param expiry    The expiry of the attribute.
 */
error Auction__AttributeExpired(string attribute, uint256 expiry);

/**
 * @notice Raised when user type is invalid.
 *
 * @param userType The `userType` of the account.
 * @param required The required `userType`.
 */
error Auction__InvalidUserType(uint256 userType, uint256 required);

/**
 * @notice Raised when a bid was placed but it is not high enough.
 *
 * @param bid           The bid placed.
 * @param highestBid    The current highest bid.
 */
error Auction__BidTooLow(uint256 bid, uint256 highestBid);

/**
 * @notice Raised bidder tries to outbid themselves.
 */
error Auction__IsHighestBidder();

/**
 * @notice Raised when payable function receives no value.
 */
error Auction__ZeroValue();

/**
 * @notice Raised when a transfer has failed.
 */
error Auction__TransferFailed();
