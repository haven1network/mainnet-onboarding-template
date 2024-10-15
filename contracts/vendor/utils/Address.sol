// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @notice Raised when an attempt is made to use the zero address in a
 * situation that is not allowed.
 */
error Address__ZeroAddress();

/**
 * @title Address
 *
 * @author The Haven1 Development Team
 *
 * @dev A library that contains collection of functions related to addresses
 */
library Address {
    /**
     * @notice Asserts that the given address is not the zero address.
     *
     * @param addr The address to check.
     */
    function assertNotZero(address addr) internal pure {
        if (addr == address(0)) {
            revert Address__ZeroAddress();
        }
    }
}
