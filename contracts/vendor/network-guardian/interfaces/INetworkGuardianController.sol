// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./INetworkGuardian.sol";
import { Range } from "../lib/Array.sol";

/**
 * @title INetworkGuardianController
 *
 * @author The Haven1 Development Team.
 *
 * @notice Interface for the `NetworkGuardianController`.
 */
interface INetworkGuardianController {
    /* EVENTS
    ==================================================*/
    /**
     * @notice Emitted when a contract is registered with this contract.
     *
     * @param addr The newly registered contract.
     */
    event Registered(address indexed addr);

    /**
     * @notice Emitted when a contract is paused.
     *
     * @param paused    The contract that was paused.
     * @param pausedBy  The Network Guardian that initiated the pause.
     */
    event Paused(address indexed paused, address indexed pausedBy);

    /**
     * @notice Emitted when a contract is unpaused.
     *
     * @param unpaused   The contract that was paused.
     * @param unpausedBy The Network Guardian that initiated the pause.
     */
    event Unpaused(address indexed unpaused, address indexed unpausedBy);

    /**
     * @notice Emitted when an attempt to pause a contract fails.
     *
     * @param addr The address of the contract that was not paused.
     */
    event PauseFailed(address indexed addr);

    /**
     * @notice Emitted when an attempt to un;pause a contract fails.
     *
     * @param addr The address of the contract that was not unpaused.
     */
    event UnpauseFailed(address indexed addr);

    /**
     * @notice Emitted when the Haven1 Association address is updated.
     *
     * @param prev The previous address.
     * @param curr The new address.
     */
    event AssociationUpdated(address indexed prev, address indexed curr);

    /* FUNCTIONS
    ==================================================*/

    /** @notice Registers a contract with this contract.
     *
     * @param addr The address to register.
     *
     * @dev Requirements:
     * -    The contract address must not be the zero address.
     * -    The contract address must not already be registered.
     * -    The contract must support the `NetworkGuardian` interface.
     *
     * Emits a `Registered` event.
     */
    function register(address addr) external;

    /**
     * @notice Allows a Network Guardian to pause the operation of a contract.
     *
     * @param addr The address of the contract to pause.
     * @param safe Whether the pause should be called safely.
     *
     * @dev Requirements:
     * -    The caller must have the role: `NETWORK_GUARDIAN`.
     * -    The contract must support the `NetworkGuardian` interface.
     * -    If `safe` is `true`, the address must not be the zero address.
     * -    If `safe` is `true`, contract must not already be paused.
     *
     * Emits a `Paused` event.
     */
    function pause(INetworkGuardian addr, bool safe) external;

    /**
     * @notice Allows a Network Guardian to pause the operation of multiple
     * contracts.
     *
     * @param addrs An array of contract addresses to pause.
     * @param safe  Whether the pause should be called safely.
     *
     * @dev Requirements:
     * -    The caller must have the role: `NETWORK_GUARDIAN`.
     * -    The contract must support the `NetworkGuardian` interface.
     * -    If `safe` is `true`, the address must not be the zero address.
     * -    If `safe` is `true`, contract must not already be paused.
     *
     * Emits a `Paused` event for each contract that is successfully paused.
     */
    function pauseMultiple(INetworkGuardian[] memory addrs, bool safe) external;

    /**
     * @notice Allows a Network Guardian to pause the operation of multiple
     * contracts. Similar to `pauseMultiple`, but rather than supplying an array
     * of addresses, this function takes a range (start and end indexes within
     * the `_registeredAddresses` array).
     *
     * @param start The start index (inclusive).
     * @param end   The end index (exclusive).
     * @param safe  Whether the pause should be called safely.
     *
     * @dev Requirements:
     * -    The caller must have the role: `NETWORK_GUARDIAN`.
     * -    The contract must support the `NetworkGuardian` interface.
     * -    The supplied range must be valid.
     * -    If `safe` is `true`, the address must not be the zero address.
     * -    If `safe` is `true`, contract must not already be paused.
     *
     * Emits a `Paused` event for each contract that is successfully paused.
     */
    function pauseRange(uint256 start, uint256 end, bool safe) external;

    /**
     * @notice Allows the admin to resume the operation of a contract.
     *
     * @param addr The address of the contract to unpause.
     * @param safe Whether the unpause should be called safely.
     *
     * @dev Requirements:
     * -    The caller must have the role: `DEFAULT_ADMIN_ROLE`.
     * -    The contract must support the `NetworkGuardian` interface.
     * -    If `safe` is `true`, the address must not be the zero address.
     * -    If `safe` is `true`, contract must be paused.
     *
     * @dev Will emit an `Unpaused` event.
     */
    function unpause(INetworkGuardian addr, bool safe) external;

    /**
     * @notice Allows the admin to resume the operation of multiple contracts.
     *
     * @param addrs An array of contract addresses to unpause.
     * @param safe  Whether the unpause should be called safely.
     *
     * @dev Requirements:
     * -    The caller must have the role: `DEFAULT_ADMIN_ROLE`.
     * -    The contract must support the `NetworkGuardian` interface.
     * -    If `safe` is `true`, the address must not be the zero address.
     * -    If `safe` is `true`, contract must be paused.
     *
     * Emits an `Unpaused` event for each contract that is successfully unpaused.
     */
    function unpauseMultiple(
        INetworkGuardian[] memory addrs,
        bool safe
    ) external;

    /**
     * @notice Allows the admin to resume the operation of multiple contracts.
     * Similar to `unpauseMultiple`, but rather than supplying an array of
     * addresses, this function takes a range (start and end indexes within the
     * `_registeredAddresses` array).
     *
     * @param start The start index (inclusive).
     * @param end   The end index (exclusive).
     * @param safe  Whether the unpause should be called safely.
     *
     * @dev Requirements:
     * -    The caller must have the role: `DEFAULT_ADMIN_ROLE`.
     * -    The contract must support the `NetworkGuardian` interface.
     * -    The supplied range must be valid.
     * -    If `safe` is `true`, the address must not be the zero address.
     * -    If `safe` is `true`, contract must not already be unpaused.
     *
     * Emits an `Unpaused` event for each contract that is successfully paused.
     */
    function unpauseRange(uint256 start, uint256 end, bool safe) external;

    /**
     * @notice Sets the association address.
     *
     * @param addr The new address to set.
     *
     * @dev Requirements:
     * -    Caller must have the role: `DEFAULT_ADMIN_ROLE`.
     * -    The address supplied must not be the zero address.
     *
     * Emits an `AssociationUpdated` event.
     */
    function setAssociation(address addr) external;

    /**
     * @notice Returns the Haven1 Association address.
     *
     * @return The Haven1 Association address.
     */
    function association() external view returns (address);

    /**
     * @notice Returns whether an address is registered with this controller.
     *
     * @param addr The address to check.
     *
     * @return True if the address is registered, false otherwise.
     */
    function isRegistered(address addr) external view returns (bool);

    /**
     * @notice Returns the number of contracts registered with this controller.
     *
     * @return The number of contracts registered with this controller.
     */
    function registeredCount() external view returns (uint256);

    /**
     * @notice Returns an array of all the currently registered addresses.
     *
     * @return An array of all the currently registered addresses.
     */
    function registeredAddresses()
        external
        view
        returns (INetworkGuardian[] memory);

    /**
     * @notice Retrieves a registered address from the `_registeredAddresses`
     * array by its index.
     *
     * @param idx The index of the address to return.
     *
     * @return The address located at the specified index within the
     * `_registeredAddresses` array.
     *
     * @dev Requirements:
     * -    The index must be within bounds.
     */
    function registeredAddressByIndex(
        uint256 idx
    ) external view returns (INetworkGuardian);

    /**
     * @notice Retrieves all registered contract addresses within a specified
     * range from the `_registeredAddresses` array.
     *
     * @param start The start index (inclusive).
     * @param end   The end index (exclusive).
     *
     * @return An array containing all registered contract addresses within the
     * specified range.
     *
     * @dev Requirements:
     * - The provided range must be valid.
     */

    function registeredAddressByRange(
        uint256 start,
        uint256 end
    ) external view returns (INetworkGuardian[] memory);

    /**
     * @notice Returns an array of ranges that may be used to safely iterate
     * over the `_registeredAddresses` array.
     *
     * @return An array of ranges that may be used to safely iterate over the
     * `_registeredAddresses` array.
     */
    function getRanges() external view returns (Range[] memory);
}
