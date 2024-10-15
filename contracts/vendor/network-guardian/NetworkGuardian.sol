// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import { INetworkGuardianController } from "./interfaces/INetworkGuardianController.sol";
import { INetworkGuardian } from "./interfaces/INetworkGuardian.sol";
import { Address } from "../utils/Address.sol";

/**
 * @title NetworkGuardian
 *
 * @author The Haven1 Development Team
 *
 * @notice An abstract contract that:
 * -    Establishes the Network Guardian role (`NETWORK_GUARDIAN`). Will only
 *      be assigned to the Network Guardian Controller and the Haven1
 *      Association. This role is responsible for pausing and unpausing the
 *      inheriting contract.
 *
 * -    Establishes the Operator role (`OPERATOR_ROLE`). On deployment, it will
 *      be assigned to the Haven1 Association. This role is responsible for
 *      executing restricted actions that do not require approval by the admin.
 *
 * -    Standardizes the registration of the inheriting contract with the
 *      Network Guardian Controller.
 *
 * -    Standardizes upgrading the inheriting contract.
 *
 * -    Exposes protected APIs for pausing and unpausing the contract. These
 *      actions are callable only by an account with the `NETWORK_GUARDIAN`
 *      role.
 *
 * -    Declares the Haven1 Association address for use in all inheriting
 *      contracts.
 *
 * @dev Must be implemented by all native and developed contracts. Because of
 * this, this contract can be thought of as a "base" upon which all Haven1
 * contracts are built. Standardizing aspects such as the assignment of the
 * Haven1 Association address and the `OPERATOR_ROLE` will greatly reduce
 * boilerplate in the inheriting contracts.
 *
 * Inheriting contracts __must__ add the `whenNotGuardianPaused` modifier to all
 * public or external functions that modify state.
 *
 * Note that inheriting contracts will also gain access to:
 * -    Initializable;
 * -    UUPSUpgradeable;
 * -    ContextUpgradeable;
 * -    ERC165Upgradeable; and
 * -    AccessControlUpgradeable.
 *
 * Inheriting contracts that are not written by the Haven1 Association
 * __must not__ assign the following roles to any address:
 * -    `DEFAULT_ADMIN_ROLE`;
 * -    `OPERATOR_ROLE`; or
 * -    `NETWORK_GUARDIAN`.
 *
 * Inheriting contracts must override `supportsInterface`.
 *
 * Typically, the last contract in the inheritance chain should call
 * `__NetworkGuardian_init`.
 */
abstract contract NetworkGuardian is
    Initializable,
    UUPSUpgradeable,
    ContextUpgradeable,
    ERC165Upgradeable,
    AccessControlUpgradeable,
    INetworkGuardian
{
    /* TYPE DECLARATIONS
    ==================================================*/
    using Address for address;

    /* STATE
    ==================================================*/
    /**
     * @notice The Network Guardian role.
     *
     * @dev Permissioned to pause and unpause the operation of the inheriting
     * contract. Assigned only to the Haven1 Association and the Network
     * Guardian Controller.
     */
    bytes32 public constant NETWORK_GUARDIAN = keccak256("NETWORK_GUARDIAN");

    /**
     * @notice The Network Operator role.
     *
     * @dev Responsible for executing restricted actions that do not require
     * approval by the admin.
     */
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /**
     * @notice The Haven1 Association address.
     */
    address private _association;

    /**
     * @notice The `NetworkGuardianController` address.
     */
    INetworkGuardianController private _controller;

    /**
     * @notice Whether this contract has been paused by a Network Guardian.
     */
    bool private _guardianPaused;

    /* ERRORS
    ==================================================*/
    /**
     * @notice Raised when an attempt is made to register an already registered
     * contract.
     */
    error NetworkGuardian__AlreadyRegistered();

    /**
     * @notice Raised when an attempt is made to access a feature that requres
     * the contract to be active, but it is paused.
     */
    error NetworkGuardian__Paused();

    /**
     * @notice Raised when an attempt is made to access a feature that requres
     * the contract to be paused, but it is active.
     */
    error NetworkGuardian__NotPaused();

    /* MODIFIERS
    ==================================================*/

    /**
     * @dev Modifier to make a function callable only when the contract is not
     * Guardian paused.
     *
     * Requirements:
     *
     * - The contract must not be Guardian paused.
     */
    modifier whenNotGuardianPaused() {
        _requireNotGuardianPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is
     * Guardian paused.
     *
     * Requirements:
     *
     * - The contract must be Guardian paused.
     */
    modifier whenGuardianPaused() {
        _requireGuardianPaused();
        _;
    }

    /* FUNCTIONS
    ==================================================*/

    /* Init
    ========================================*/

    /**
     * @notice Initializes the `NetworkGuardian` contract.
     *
     * @param association_  The Haven1 Association address.
     * @param controller_   The Network Guardian Controller address.
     */
    function __NetworkGuardian_init(
        address association_,
        address controller_
    ) internal onlyInitializing {
        __AccessControl_init();
        __ERC165_init();
        __UUPSUpgradeable_init();
        __NetworkGuardian_init_unchained(association_, controller_);
    }

    /**
     * @param association_  The Haven1 Association address.
     * @param controller_   The Network Guardian Controller address.
     *
     * @dev Requirements:
     * -    The provided addresses must not be the zero address.
     *
     * @dev For more information on the "unchained" method and multiple
     * inheritance see:
     * https://docs.openzeppelin.com/contracts/4.x/upgradeable#multiple-inheritance
     */
    function __NetworkGuardian_init_unchained(
        address association_,
        address controller_
    ) internal onlyInitializing {
        association_.assertNotZero();
        controller_.assertNotZero();

        _association = association_;
        _controller = INetworkGuardianController(controller_);

        _grantRole(DEFAULT_ADMIN_ROLE, association_);
        _grantRole(OPERATOR_ROLE, association_);

        _grantRole(NETWORK_GUARDIAN, association_);
        _grantRole(NETWORK_GUARDIAN, controller_);

        _guardianPaused = false;
    }

    /* External
    ========================================*/

    /**
     * @inheritdoc INetworkGuardian
     */
    function register() external {
        _controller.register(address(this));
    }

    /**
     * @inheritdoc INetworkGuardian
     */
    function guardianPause() external onlyRole(NETWORK_GUARDIAN) {
        _guardianPause();
    }

    /**
     * @inheritdoc INetworkGuardian
     */
    function guardianUnpause() external onlyRole(NETWORK_GUARDIAN) {
        _guardianUnpause();
    }

    /**
     * @inheritdoc INetworkGuardian
     */
    function setAssociation(
        address addr
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        addr.assertNotZero();

        _grantRole(DEFAULT_ADMIN_ROLE, addr);
        _grantRole(OPERATOR_ROLE, addr);
        _grantRole(NETWORK_GUARDIAN, addr);

        _revokeRole(NETWORK_GUARDIAN, _association);
        _revokeRole(OPERATOR_ROLE, _association);
        _revokeRole(DEFAULT_ADMIN_ROLE, _association);

        _association = addr;
    }

    /**
     * @inheritdoc INetworkGuardian
     */
    function setController(address addr) external onlyRole(DEFAULT_ADMIN_ROLE) {
        addr.assertNotZero();

        _revokeRole(NETWORK_GUARDIAN, address(_controller));
        _grantRole(NETWORK_GUARDIAN, addr);

        _controller = INetworkGuardianController(addr);
    }

    /* Public
    ========================================*/

    /**
     * @inheritdoc INetworkGuardian
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(AccessControlUpgradeable, ERC165Upgradeable, INetworkGuardian)
        returns (bool)
    {
        return
            interfaceId == type(INetworkGuardian).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc INetworkGuardian
     */
    function controller() public view returns (address) {
        return address(_controller);
    }

    /**
     * @inheritdoc INetworkGuardian
     */
    function association() public view returns (address) {
        return _association;
    }

    /**
     * @inheritdoc INetworkGuardian
     */
    function guardianPaused() public view returns (bool) {
        return _guardianPaused;
    }

    /* Internal
    ========================================*/

    /**
     * @notice This function is overridden to protect the contract by only
     * allowing the admin to upgrade it.
     *
     * @param newImplementation new implementation address.
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    /**
     * @dev Will revert if the contract is paused.
     */
    function _requireNotGuardianPaused() internal view {
        if (guardianPaused()) {
            revert NetworkGuardian__Paused();
        }
    }

    /**
     * @dev Will revert if the contract is not paused.
     */
    function _requireGuardianPaused() internal view {
        if (!guardianPaused()) {
            revert NetworkGuardian__NotPaused();
        }
    }

    /* Private
    ========================================*/

    /**
     * @dev Pauses the contract.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _guardianPause() private whenNotGuardianPaused {
        _guardianPaused = true;
        emit GuardianPaused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _guardianUnpause() private whenGuardianPaused {
        _guardianPaused = false;
        emit GuardianUnpaused(_msgSender());
    }

    /* GAP
    ==================================================*/

    /**
     * @dev This empty reserved space allows new state variables to be added
     * without compromising the storage compatibility with existing deployments.
     *
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     *
     * As new variables are added, be sure to reduce the gap as required.
     * For e.g., if the starting `__gap` is `25` and a new variable is added
     * (256 bits in size or part thereof), the gap must now be reduced to `49`.
     */
    uint256[50] private __gap;
}
