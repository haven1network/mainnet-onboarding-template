// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Address } from "../../../vendor/utils/Address.sol";
import { Auction__InvalidAuctionKind, Auction__InvalidAuctionLength } from "./Errors.sol";

struct Config {
    uint256 kind;
    uint256 length;
    uint256 startingBid;
    address nft;
    uint256 nftID;
    address beneficiary;
}

library ConfigUtils {
    /**
     * @dev The minimum time an auction has to last for.
     */
    uint256 internal constant _MIN_LENGTH = 1 days;

    /**
     * @dev Auction Type: Retail.
     *
     * This value means that only accounts marked as `retail` (`1`) on the
     * `ProofOfIdentity` contract will be allowed to participate in the auction.
     */
    uint256 internal constant _RETAIL = 1;

    /**
     * @dev Auction Type: Institution.
     *
     * This value means that only accounts marked as `institution` (`2`) on the
     * `ProofOfIdentity` contract will be allowed to participate in the auction.
     */
    uint256 internal constant _INSTITUTION = 2;

    /**
     * @dev Auction Type: All.
     *
     * Means that both `retial` (`1`) and `institution` (`2`) accounts as will
     * be allowed to participate in the auction.
     */
    uint256 internal constant _ALL = 3;

    /**
     * @notice Validates a given auction configuration.
     *
     * @param cfg The auction configuration struct.
     *
     * @dev Requirements:
     * -    Neither the NFT nor the beneficiary address can be the zero address.
     * -    The auction kind must be either 1, 2, or 3.
     * -    The auction length must be greater than, or equal to, the minimum
     *      required length.
     */
    function assertValid(Config memory cfg) internal pure {
        Address.assertNotZero(cfg.nft);
        Address.assertNotZero(cfg.beneficiary);

        if (cfg.kind == 0 || cfg.kind > _ALL) {
            revert Auction__InvalidAuctionKind(cfg.kind);
        }

        if (cfg.length < _MIN_LENGTH) {
            revert Auction__InvalidAuctionLength(cfg.length, _MIN_LENGTH);
        }
    }
}
