// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title INetworkGuardian
 *
 * @author The Haven1 Development Team.
 *
 * @notice Interface for the `NetworkGuardian`.
 */
interface INetworkGuardian {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event GuardianPaused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event GuardianUnpaused(address account);

    /**
     * @notice Registers this contract with the Network Guardian Controller.
     *
     * @dev Requirements:
     * -    Must not already be registered.
     *
     * As this contract is upgradeable, we cannot include registration as
     * part of contract initialization. Before initialization, there is no
     * appropriate way to permission the call or for the Network Guardian
     * Controller to confirm interface support.
     *
     * No event is emitted here. Rather, it is standardized in the Network
     * Guardian Controller. See {NetworkGuardianController-register}.
     */
    function register() external;

    /**
     * @notice Allows a Network Guardian to pause operation of this contract.
     *
     * @dev Requirements:
     * -    Caller must have the role: `NETWORK_GUARDIAN`.
     * -    The contract must not already be paused.
     *
     * Is named `guardianPause` to leave the `pause` namespace available
     * for inheriting contracts.
     *
     */
    function guardianPause() external;

    /**
     * @notice Allows the admin to resume the operation of this contract.
     *
     * @dev Requirements:
     * -    Caller must have the role: `NETWORK_GUARDIAN`.
     * -    The contract must already be paused.
     *
     * Takes `unpause` namespace and cannot be overridden.
     */
    function guardianUnpause() external;

    /**
     * @notice Sets the association address and updates permissions.
     *
     * @param addr The address to set.
     *
     * @dev Requirements:
     * -    Caller must have the role: `DEFAULT_ADMIN_ROLE`.
     * -    The address supplied must not be the zero address.
     */
    function setAssociation(address addr) external;

    /**
     * @notice Sets the Network Guardian Controller address and updates
     * permissions.
     *
     * @param addr The address to set.
     *
     * @dev Requirements:
     * -    Caller must have the role: `DEFAULT_ADMIN_ROLE`.
     * -    The address supplied must not be the zero address.
     */
    function setController(address addr) external;

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * @dev Must be overridden by the inheriting contract.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    /**
     * @notice Returns the `NetworkGuardianController` address.
     *
     * @return The `NetworkGuardianController` address.
     */
    function controller() external view returns (address);

    /**
     * @notice Returns the Haven1 Association address.
     *
     * @return The Haven1 Association address.
     */
    function association() external view returns (address);

    /**
     * @dev Returns true if the contract is Guardian paused, and false otherwise.
     *
     * @return True if the contract is Guardian paused, and false otherwise.
     */
    function guardianPaused() external view returns (bool);
}
