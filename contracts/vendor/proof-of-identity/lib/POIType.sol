// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ProofOfIdentity__PrincipalRequired } from "./Errors.sol";

/**
 * @dev Represents the type of a Proof of Identity NFT.
 * An issued NFT can be either a principle or an auxiliary entity.
 */
enum POIType {
    NOT_ISSUED,
    PRINCIPAL,
    AUXILIARY
}

/**
 * @dev Represents an account's suspended status. Is indexed in the
 * `AccountStatusUpdated` event.
 */
enum AccountStatus {
    UNSUSPENDED,
    SUSPENDED
}

/**
 * @title AttributeUtils
 *
 * @author The Haven1 Development Team
 *
 * @dev Library that contains a collection of utils for the `POIType`.
 */
library POITypeUtils {
    /**
     * @dev Asserts that a given `POIType` is of type `POIType.PRINCIPAL`.
     *
     * @param t The POIType to check.
     */
    function assertIsPrincipal(POIType t) internal pure {
        if (t != POIType.PRINCIPAL) {
            revert ProofOfIdentity__PrincipalRequired();
        }
    }
}
