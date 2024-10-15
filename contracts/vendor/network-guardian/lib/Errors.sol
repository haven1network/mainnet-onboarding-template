// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice Raised when an attempt is made to register an already registered
 * contract.
 *
 * @param addr The address of the already registered contract.
 */
error NetworkGuardianController__AlreadyRegistered(address addr);

/**
 * @notice Raised when an attempt is made to register an address that does not
 * support the `NetworkGuardian` interface.
 *
 * @param addr The invalid address.
 */
error NetworkGuardianController__UnsupportedInterface(address addr);

/**
 * @notice Raised when an attempt is made to iterate over an array with a length
 * greater than the maximum allowed.
 *
 * @param len The length of the given array.
 * @param max The max allowed length.
 */
error NetworkGuardianController__MaxIterations(uint256 len, uint256 max);

/**
 * @notice Raised when an attempt is made to iterate over an invalid range of an
 * array.
 */
error NetworkGuardianController__InvalidRange();

/**
 * @notice Raised when an attempt is made to access an item in an array at an
 * invalid index.
 */
error NetworkGuardianController__IndexOutOfBounds();

/**
 * @notice Raised when an attempt is made to iterate over an array with zero
 * elements.
 */
error NetworkGuardianController__ZeroLength();

/**
 * @notice Raised when an attempt is made to pause a contract and it fails.
 */
error NetworkGuardianController__PauseFailed();

/**
 * @notice Raised when an attempt is made to unpause a contract and it fails.
 */
error NetworkGuardianController__UnpauseFailed();
