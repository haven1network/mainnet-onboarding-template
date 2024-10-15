// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import { H1DevelopedApplication } from "../../vendor/h1-developed-application/H1DevelopedApplication.sol";
import { IProofOfIdentity } from "../../vendor/proof-of-identity/interfaces/IProofOfIdentity.sol";

import "./lib/Errors.sol";
import { Config, ConfigUtils } from "./lib/NFTAuctionConfig.sol";
import { Address } from "../../vendor/utils/Address.sol";

/**
 * @title NFTAuction
 *
 * @author The Haven1 Development Team
 *
 * @notice An NFT Auction contract that demonstrates how to implement, and
 * interact with, the `H1DevelopedApplication` contract. Also provides example
 * interactions with the `ProofOfIdentity` contract in order to permission the
 * auction.
 *
 * @dev As noted as a requirement in the `H0DevelopedApplication` documentation,
 * all public and external functions that modify state have both the
 * `whenNotGuardianPaused` and `developerFee` modifiers applied.
 *
 * As this contract does store native H1, it marks `storesH1` as `true` and opts
 * not to refund users any excess H1 they send in to pay fees.
 */
contract NFTAuction is H1DevelopedApplication, ReentrancyGuardUpgradeable {
    /* TYPE DECLARATIONS
    ==================================================*/
    using ConfigUtils for Config;
    using Address for address;

    /* STATE VARIABLES
    ==================================================*/
    /**
     * @dev The address that will receive the proceeds of the auction  after it
     * ends.
     */
    address private _beneficiary;

    /**
     * @dev The kind of the auction, either 1, 2 or 3.
     */
    uint256 private _auctionKind;

    /**
     * @dev Whether the auction has started.
     */
    bool private _started;

    /**
     * @dev Whether the auction has ended.
     */
    bool private _finished;

    /**
     * @dev The length, in seconds, of the auction.
     */
    uint256 private _auctionLength;

    /**
     * @dev The timestamp of when the auction ends. If 0, the auction has not
     * started.
     *
     * End time = _auctionStartTime + _auctionLength;
     */
    uint256 private _auctionEndTime;

    /**
     * @dev The Proof of Identity Contract.
     */
    IProofOfIdentity private _proofOfIdentity;

    /**
     * @dev The address of the highest bidder.
     */
    address private _highestBidder;

    /**
     * @dev The highest bid.
     */
    uint256 private _highestBid;

    /**
     * @dev The NFT prize.
     */
    IERC721Upgradeable private _nft;

    /**
     * @dev The ID of the NFT prize.
     */
    uint256 private _nftId;

    /* EVENTS
    ==================================================*/
    /**
     * @notice Emitted when the auction is started.
     *
     * @param endTime The timestamp of the end of the auction.
     */
    event AuctionStarted(uint256 endTime);

    /**
     * @notice Emitted when the auction has finished.
     *
     * @param winner    The address of the winner.
     * @param bid       The winning bid.
     */
    event AuctionEnded(address indexed winner, uint256 bid);

    /**
     * @notice Emitted when a bid has been placed.
     *
     * @param bidder The address of the bidder.
     * @param amount The bid amount.
     */
    event BidPlaced(address indexed bidder, uint256 amount);

    /**
     * Emitted when the NFT has been sent to the winner.
     *
     * @param winner The address of the winner.
     * @param amount The winning bid.
     */
    event NFTSent(address indexed winner, uint256 amount);

    /* MODIFIERS
    ==================================================*/
    /**
     * @dev Modifier to be used on any functions that require a user be
     * permissioned per this contract's definition.
     *
     * Requirements:
     * -    The account must have a Proof of Identity NFT.
     * -    The account must not be suspended.
     * -    The account is of the requisite user type.
     */
    modifier onlyPermissioned(address account) {
        if (!_hasID(account)) {
            revert Auction__NoIdentityNFT();
        }

        if (_isSuspended(account)) {
            revert Auction__Suspended();
        }

        _assertValidUserType(account);
        _;
    }

    /* FUNCTIONS
    ==================================================*/
    /* Constructor
    ========================================*/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /* Initialize
    ========================================*/

    /**
     * @notice Initializes the `NFTAuction` contract.
     *
     * @param proofOfIdentity       The Proof of Identity address
     * @param feeContract           The Fee Contract address.
     * @param guardianController    The Network Guardian Controller address.
     * @param association           The Haven1 Association address.
     * @param developer             The address of the contract's developer.
     * @param feeCollector          The address of the developer's fee collector.
     * @param fnSigs                Function signatures for which fees will be set.
     * @param fnFees                Fees that will be set for their `fnSigs` counterparts.
     * @param auctionConfig         A struct containing the auction configuration.
     */
    function initialize(
        address proofOfIdentity,
        address feeContract,
        address guardianController,
        address association,
        address developer,
        address feeCollector,
        string[] calldata fnSigs,
        uint256[] calldata fnFees,
        Config calldata auctionConfig
    ) external initializer {
        proofOfIdentity.assertNotZero();
        auctionConfig.assertValid();

        __ReentrancyGuard_init();
        __H1DevelopedApplication_init(
            feeContract,
            guardianController,
            association,
            developer,
            feeCollector,
            fnSigs,
            fnFees,
            true
        );

        _proofOfIdentity = IProofOfIdentity(proofOfIdentity);

        _auctionKind = auctionConfig.kind;
        _auctionLength = auctionConfig.length;
        _highestBid = auctionConfig.startingBid;
        _nft = IERC721Upgradeable(auctionConfig.nft);
        _nftId = auctionConfig.nftID;
        _beneficiary = auctionConfig.beneficiary;
    }

    /* External
    ========================================*/
    /**
     * @notice Starts the auction.
     *
     * @dev Requirements:
     * -    Only callable by an account with the role: `DEV_ADMIN_ROLE`.
     * -    Only callable when the contract is not paused.
     * -    Must provide the developer fee, if any.
     * -    Only callable if the auction is not started.
     *
     * Emits an `AuctionStarted` event.
     */
    function startAuction()
        external
        payable
        whenNotGuardianPaused
        developerFee(false, false)
        onlyRole(DEV_ADMIN_ROLE)
    {
        // There is no need to check `_finished` because, once the auction has
        // started, `_started` is not flipped back to false.
        if (_started) {
            revert Auction__AuctionActive();
        }

        _nft.transferFrom(msg.sender, address(this), _nftId);

        _started = true;
        _auctionEndTime = block.timestamp + _auctionLength;

        emit AuctionStarted(_auctionEndTime);
    }

    /**
     * @notice Places a bid. If the bid placed is not higher than the current
     * highest bid, this function will revert.
     *
     * If the bid is sufficiently high, the previous bid will be refunded to the
     * previous highest bidder.
     *
     * @dev Requirements:
     * -    Only callable when the contract is not paused.
     * -    Must provide the developer fee, if any.
     * -    The caller must be allowed to bid.
     * -    The auction must have active.
     * -    The new bid must be higher than the current highest bid.
     * -    The caller must not already be the current highest bidder.
     *
     * Emits a `BidPlaced` event.
     */
    function bid()
        external
        payable
        nonReentrant
        whenNotGuardianPaused
        developerFee(true, false)
        onlyPermissioned(msg.sender)
    {
        if (!hasStarted()) {
            revert Auction__AuctionNotStarted();
        }

        if (hasFinished()) {
            revert Auction__AuctionFinished();
        }

        uint256 val = msgValueAfterFee();
        if (val == 0) {
            revert Auction__ZeroValue();
        }

        if (msg.sender == _highestBidder) {
            revert Auction__IsHighestBidder();
        }

        if (val <= _highestBid) {
            revert Auction__BidTooLow(val, _highestBid);
        }

        _refundBid();

        _highestBidder = msg.sender;
        _highestBid = val;

        emit BidPlaced(msg.sender, val);
    }

    /**
     * @notice Ends the auction, transferring the NFT to the winner and the
     * proceeds to the beneficiary.
     *
     * @dev Requirements:
     * -    Only callable when the contract is not paused.
     * -    Must provide the developer fee, if any.
     * -    Callable by anyone, as long as the end timestamp has been reached.
     *
     * Emits `NFTSent` and `AuctionEnded` events.
     */
    function endAuction()
        external
        payable
        nonReentrant
        whenNotGuardianPaused
        developerFee(true, false)
    {
        if (!hasStarted()) {
            revert Auction__AuctionNotStarted();
        }

        if (inProgress()) {
            revert Auction__AuctionActive();
        }

        if (_finished) {
            revert Auction__AuctionFinished();
        }

        _finished = true;

        if (_highestBidder == address(0)) {
            _nft.safeTransferFrom(address(this), _beneficiary, _nftId);
        } else {
            _nft.safeTransferFrom(address(this), _highestBidder, _nftId);
            _transferExn(_beneficiary, address(this).balance);
            emit NFTSent(_highestBidder, _highestBid);
        }

        emit AuctionEnded(_highestBidder, _highestBid);
    }

    /**
     * @notice Returns whether an account is eligible to participate in the
     * auction.
     *
     * @param addr The address to check.
     *
     * @return True if the account can place a bid, false otherwise.
     *
     * @dev Requirements:
     * -    The account must have a Proof of Identity NFT.
     * -    The account must not be suspended.
     * -    The account is of the requisite user type.
     */
    function accountEligible(address addr) external view returns (bool) {
        return _hasID(addr) && _isValidUserType(addr) && !_isSuspended(addr);
    }

    /**
     * @notice Returns the highest bidder. If the auction has ended, returns
     * the winner of the auction.
     *
     * @return The address of the highest or winning bidder.
     */
    function highestBidder() external view returns (address) {
        return _highestBidder;
    }

    /**
     * @notice Returns the highest bid. If the auction has ended, returns the
     * winning bid.
     *
     * @return The highest or winning bid.
     */
    function highestBid() external view returns (uint256) {
        return _highestBid;
    }

    /**
     * @notice Returns the address of the prize NFT and the NFT ID.
     *
     * @return The address of the prize NFT and its ID.
     */
    function nft() external view returns (address, uint256) {
        return (address(_nft), _nftId);
    }

    /**
     * @notice Returns the timestamp of when the auction is finished.
     *
     * @return The timestamp of when the auction is finished.
     */
    function finishTime() external view returns (uint256) {
        return _auctionEndTime;
    }

    /**
     * @notice Returns the kind of the auction:
     * -   1: Retail
     * -   2: Institution
     * -   3: All
     *
     * @return The kind of the auction.
     */
    function auctionKind() external view returns (uint256) {
        return _auctionKind;
    }

    /**
     * @notice Returns the length, in seconds, of the auction.
     *
     * @return The length, in seconds, of the auction.
     */
    function auctionLength() external view returns (uint256) {
        return _auctionLength;
    }

    /**
     * @notice Returns the address of the auction's beneficiary.
     *
     * @return The address of the auction's beneficiary.
     */
    function beneficiary() external view returns (address) {
        return address(_beneficiary);
    }

    /* Public
    ========================================*/
    /**
     * @notice Returns whether the auction has started.
     *
     * @return True if it has started, false otherwise.
     */
    function hasStarted() public view returns (bool) {
        return _started;
    }

    /**
     * @notice Returns whether the auction has finished.
     *
     * @return True if it has finished, false otherwise.
     */
    function hasFinished() public view returns (bool) {
        return _finished || block.timestamp > _auctionEndTime;
    }

    /**
     * @notice Returns whether the auction is in progress.
     *
     * @return True if it is in progress, false otherwise.
     */
    function inProgress() public view returns (bool) {
        return _started && block.timestamp < _auctionEndTime;
    }

    /* Private
    ========================================*/
    /**
     * @notice Sends an `amount` of H1 to the `to` address.
     *
     * @param to        The recipient address.
     * @param amount    The amount to send.
     *
     * @dev The calling code must implement `nonReentrant` as this call
     * transfers control to the `_highestBidder`.
     */
    function _transferExn(address to, uint256 amount) private {
        (bool success, ) = payable(to).call{ value: amount }("");
        if (!success) revert Auction__TransferFailed();
    }

    /**
     * @notice Refunds the previous highest bidder.
     *
     * @dev The calling code must implement `nonReentrant` as this call transfers
     * control to the `_highestBidder`.
     */
    function _refundBid() private {
        if (_highestBidder == address(0)) return;
        _transferExn(_highestBidder, _highestBid);
    }

    /**
     * @notice Returns whether an account holds a Proof of Identity NFT.
     *
     * @param addr The account to check.
     *
     * @return True if the account holds a Proof of Identity NFT, else false.
     */
    function _hasID(address addr) private view returns (bool) {
        return _proofOfIdentity.balanceOf(addr) > 0;
    }

    /**
     * @notice Returns whether an account is suspended.
     *
     * @param addr The account to check.
     *
     * @return True if the account is suspended, false otherwise.
     */
    function _isSuspended(address addr) private view returns (bool) {
        return _proofOfIdentity.isSuspended(addr);
    }

    /**
     * @notice Checks whether a given account's `userType` is valid.
     *
     * @param addr The account to check.
     *
     * @return True if the check is valid, false otherwise.
     */
    function _isValidUserType(address addr) private view returns (bool) {
        (uint256 user, uint256 exp, ) = _proofOfIdentity.getUserType(addr);
        return (_auctionKind & user) > 0 && exp > block.timestamp;
    }

    /**
     * @notice Similar to `_isValidUserType`, but will revert if the check fails.
     *
     * @param addr The account to check.
     */
    function _assertValidUserType(address addr) private view {
        (uint256 user, uint256 exp, ) = _proofOfIdentity.getUserType(addr);

        if (!((_auctionKind & user) > 0)) {
            revert Auction__InvalidUserType(user, _auctionKind);
        }

        if (exp <= block.timestamp) {
            revert Auction__AttributeExpired("userType", exp);
        }
    }
}
