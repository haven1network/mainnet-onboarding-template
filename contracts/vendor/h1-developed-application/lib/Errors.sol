// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @notice Raised when a fee transfer has failed.
 *
 * @param to        The recipient address.
 * @param amount    The amount of the transaction.
 */
error H1Developed__FeeTransferFailed(address to, uint256 amount);

/**
 * @notice Raised when there are insufficient funds to cover the fee.
 *
 * @param available The current balance of the contract.
 * @param fee       The current fee amount.
 */
error H1Developed__InsufficientFunds(uint256 available, uint256 fee);

/**
 * @notice Raised when the length of two arrays are required to be equal and are not.
 *
 * @param a The length of the first array.
 * @param b The length of the second array.
 */
error H1Developed__ArrayLengthMismatch(uint256 a, uint256 b);

/**
 * @notice Raised when the length of an array is zero.
 */
error H1Developed__ArrayLengthZero();

/**
 * @notice Raised when an invalid function signature has been provided.
 */
error H1Developed__InvalidFnSignature();

/**
 * @notice Raised when an attempt is made to set a fee with an invalid value.
 *
 * @param fee The invalid fee amount.
 */
error H1Developed__InvalidFeeAmount(uint256 fee);

/**
 * @dev Raised when a reentrant call is made.
 */
error H1Developed__ReentrantCall();
