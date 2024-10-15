// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Raised when a transfer has failed.
 */
error FeeContract__TransferFailed();

/**
 * @dev Raised when an attempt is made to distribute fees before the minimum
 * epoch length has been met.
 */
error FeeContract__EpochLengthNotYetMet();

/**
 * @dev Raised when an invalid address has been supplied.
 *
 * @param account The invalid address that was used.
 */
error FeeContract__InvalidAddress(address account);

/**
 * @dev Raised when an invalid channel weight has been supplied.
 *
 * @param weight The invalid weight.
 */
error FeeContract__InvalidWeight(uint256 weight);

/**
 * @dev Raised when an attempt is made to add a channel in excess of the allowed
 * amount.
 */
error FeeContract__ChannelLimitReached();

/**
 * @dev Raised when each channel does not have a corresponding weight.
 */
error FeeContract__ChannelWeightMisalignment();

/**
 * @dev Raised when a channel was requested but could not be found.
 *
 * @param channel The requested channel address.
 */
error FeeContract__ChannelNotFound(address channel);

/**
 * @dev Raised when an invalid fee was supplied.
 */
error FeeContract__InvalidFee();

/**
 * @dev Raised when an attempt was made to update the grace period to a length
 * that exceeds the fee epoch.
 *
 * @param supplied  The value supplied.
 * @param max       The maximum allowed value.
 */
error FeeContract__InvalidGracePeriod(uint256 supplied, uint256 max);

/**
 * @dev Raised when an action required an EOA but a contract address was provided.
 *
 * @param addr The address that was provided.
 */
error FeeContract__OnlyEOA(address addr);
