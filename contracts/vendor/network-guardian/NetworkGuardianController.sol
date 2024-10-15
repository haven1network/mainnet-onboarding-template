// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

import "./interfaces/INetworkGuardian.sol";
import "./interfaces/INetworkGuardianController.sol";
import "./lib/Errors.sol";
import { Array, Range } from "./lib/Array.sol";
import { Address } from "../utils/Address.sol";

/**
 * @title NetworkGuardianController
 *
 * @author The Haven1 Development Team
 *
 * @notice A contract that supplies the Network Guardians with an interface to
 * pause the operation of contracts on the Haven1 network.
 *
 * Allows the account with the `DEFAULT_ADMIN_ROLE` to resume paused contracts.
 *
 * @dev All contracts deployed on the network must be registered with this
 * contract.
 *
 * It is well understood that large arrays in Solidity are generally discouraged.
 * Nevertheless, the problem that this contract aims to solve is particularly
 * amenable to their use and we deem the trade-off for transparency to be
 * worthwhile.
 *
 * For array operations within this contract, the start index is always
 * inclusive and the end index is always exclusive.
 */
contract NetworkGuardianController is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    INetworkGuardianController
{
    /* TYPE DECLARATIONS
    ==================================================*/
    enum Action {
        PAUSE,
        UNPAUSE
    }

    using ERC165CheckerUpgradeable for address;
    using Address for address;

    /* STATE
    ==================================================*/
    /**
     * @notice The maximum number of iterations allowed for a bulk pause or
     * unpause.
     *
     * @dev Given the estimated gas cost of required actions per iteration, 500
     * maximum iterations is a sensible ceiling.
     */
    uint256 public constant MAX_ITERS = 500;

    /**
     * @notice The Network Guardian role.
     *
     * @dev Accounts assigned this role will have the ability to call the
     * various pausing functions defined within this contract. Note, they will
     * not have the ability to call `pause` directly on a contract that
     * implements the `NetworkGuardian` contract - they must use this interface.
     */
    bytes32 public constant NETWORK_GUARDIAN = keccak256("NETWORK_GUARDIAN");

    /**
     * @notice The `NetworkGuardian` interface ID.
     */
    bytes4 private constant GUARDIAN_INTERFACE_ID = 0x64b581fc;

    /**
     * @notice The Haven1 Association address.
     *
     * @dev Is assigned the roles:
     * -    `DEFAULT_ADMIN_ROLE`; and
     * -    `NETWORK_GUARDIAN`.
     */
    address private _association;

    /**
     * @notice Whether a given address has been registered with this contract.
     *
     * @dev Registered contracts are known to support the `NetworkGuardian`
     * interface.
     */
    mapping(address => bool) private _registered;

    /**
     * @notice List of all the contract addresses registered with this contract.
     */
    INetworkGuardian[] private _registeredAddresses;

    /* FUNCTIONS
    ==================================================*/
    /* Constructor and Init
    ========================================*/

    /**
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the contract.
     *
     * @param association_ The Haven1 Association address.
     *
     * @dev Requirements:
     * -    The association address must not be the zero address.
     */
    function initialize(address association_) external initializer {
        association_.assertNotZero();

        __AccessControl_init();
        __UUPSUpgradeable_init();

        _association = association_;

        _grantRole(DEFAULT_ADMIN_ROLE, association_);
        _grantRole(NETWORK_GUARDIAN, association_);
    }

    /* External
    ========================================*/

    /**
     * @inheritdoc INetworkGuardianController
     */
    function register(address addr) external {
        addr.assertNotZero();

        if (_registered[addr]) {
            revert NetworkGuardianController__AlreadyRegistered(addr);
        }

        if (!addr.supportsInterface(GUARDIAN_INTERFACE_ID)) {
            revert NetworkGuardianController__UnsupportedInterface(addr);
        }

        _registered[addr] = true;
        _registeredAddresses.push(INetworkGuardian(addr));

        emit Registered(addr);
    }

    /**
     * @inheritdoc INetworkGuardianController
     */
    function pause(
        INetworkGuardian addr,
        bool safe
    ) external onlyRole(NETWORK_GUARDIAN) {
        _pause(addr, safe);
    }

    /**
     * @inheritdoc INetworkGuardianController
     */
    function pauseMultiple(
        INetworkGuardian[] memory addrs,
        bool safe
    ) external onlyRole(NETWORK_GUARDIAN) {
        _actionMultiple(Action.PAUSE, addrs, safe);
    }

    /**
     * @inheritdoc INetworkGuardianController
     */
    function pauseRange(
        uint256 start,
        uint256 end,
        bool safe
    ) external onlyRole(NETWORK_GUARDIAN) {
        _actionRange(Action.PAUSE, start, end, safe);
    }

    /**
     * @inheritdoc INetworkGuardianController
     */
    function unpause(
        INetworkGuardian addr,
        bool safe
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause(addr, safe);
    }

    /**
     * @inheritdoc INetworkGuardianController
     */
    function unpauseMultiple(
        INetworkGuardian[] memory addrs,
        bool safe
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _actionMultiple(Action.UNPAUSE, addrs, safe);
    }

    /**
     * @inheritdoc INetworkGuardianController
     */
    function unpauseRange(
        uint256 start,
        uint256 end,
        bool safe
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _actionRange(Action.UNPAUSE, start, end, safe);
    }

    /**
     * @inheritdoc INetworkGuardianController
     */
    function setAssociation(
        address addr
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        addr.assertNotZero();
        address prev = _association;
        _association = addr;

        emit AssociationUpdated(prev, addr);
    }

    /**
     * @inheritdoc INetworkGuardianController
     */
    function association() external view returns (address) {
        return _association;
    }

    /**
     * @inheritdoc INetworkGuardianController
     */
    function isRegistered(address addr) external view returns (bool) {
        return _registered[addr];
    }

    /**
     * @inheritdoc INetworkGuardianController
     */
    function registeredCount() external view returns (uint256) {
        return _registeredAddresses.length;
    }

    /**
     * @inheritdoc INetworkGuardianController
     */
    function registeredAddresses()
        external
        view
        returns (INetworkGuardian[] memory)
    {
        return _registeredAddresses;
    }

    /**
     * @inheritdoc INetworkGuardianController
     */
    function registeredAddressByIndex(
        uint256 idx
    ) external view returns (INetworkGuardian) {
        if (idx >= _registeredAddresses.length) {
            revert NetworkGuardianController__IndexOutOfBounds();
        }

        return _registeredAddresses[idx];
    }

    /**
     * @inheritdoc INetworkGuardianController
     */
    function registeredAddressByRange(
        uint256 start,
        uint256 end
    ) external view returns (INetworkGuardian[] memory) {
        uint256 len = _registeredAddresses.length;
        Array.assertValidRange(start, end, len);

        INetworkGuardian[] memory out = new INetworkGuardian[](end - start);

        uint256 i = start;
        for (i; i < end; i++) {
            out[i - start] = _registeredAddresses[i];
        }

        return out;
    }

    /**
     * @inheritdoc INetworkGuardianController
     */
    function getRanges() external view returns (Range[] memory) {
        return Array.ranges(MAX_ITERS, _registeredAddresses.length);
    }

    /* Internal
    ========================================*/

    /**
     * @notice This function is overridden to protect the contract by only
     * allowing the admin to upgrade it.
     *
     * @param newImplementation The new implementation address.
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    /* Private
    ========================================*/

    /**
     * @notice Private function that handles pausing logic.
     *
     * @param addr The address of the contract to pause.
     * @param safe Whether the pause should be called safely.
     *
     * @dev Requirements:
     * -    The contract must support the `NetworkGuardian` interface.
     * -    If `safe` is `true`, the address must not be the zero address.
     * -    If `safe` is `true`, contract must not already be paused.
     *
     * Emits a `Paused` event.
     */
    function _pause(INetworkGuardian addr, bool safe) private {
        if (safe) {
            address(addr).assertNotZero();
        }

        try addr.guardianPause() {
            emit Paused(address(addr), msg.sender);
        } catch {
            emit PauseFailed(address(addr));
            if (safe) {
                revert NetworkGuardianController__PauseFailed();
            }
        }
    }

    /**
     * @notice Private function that handles unpausing logic.
     *
     * @param addr The address of the contract to unpause.
     * @param safe Whether the pause should be called safely.
     *
     * @dev Requirements:
     * -    The contract must support the `NetworkGuardian` interface.
     * -    If `safe` is `true`, the address must not be the zero address.
     * -    If `safe` is `true`, contract must be paused.
     *
     * Emits an `Unpaused` event.
     */
    function _unpause(INetworkGuardian addr, bool safe) private {
        if (safe) {
            address(addr).assertNotZero();
        }

        try addr.guardianUnpause() {
            emit Unpaused(address(addr), msg.sender);
        } catch {
            emit UnpauseFailed(address(addr));
            if (safe) {
                revert NetworkGuardianController__UnpauseFailed();
            }
        }
    }

    /**
     * @notice Private function that handles executing multiple calls to
     * `_pause` or `_unpause`.
     *
     * @param action The action to take - either `PAUSE` or `UNPAUSE`.
     * @param addrs  Contract addresses on which to undertake the action.
     * @param safe   Whether the action should be called safely.
     *
     * @dev Requirements:
     * -    The contract must support the `NetworkGuardian` interface.
     * -    If `safe` is `true`, the address must not be the zero address.
     * -    If `safe` is `true`, each contract must not already be in the new
     *      desired state.
     */
    function _actionMultiple(
        Action action,
        INetworkGuardian[] memory addrs,
        bool safe
    ) private {
        uint256 len = addrs.length;
        if (len > MAX_ITERS) {
            revert NetworkGuardianController__MaxIterations(len, MAX_ITERS);
        }

        for (uint256 i; i < len; i++) {
            if (action == Action.PAUSE) {
                _pause(addrs[i], safe);
            } else {
                _unpause(addrs[i], safe);
            }
        }
    }

    /**
     * @notice Private function that handles executing multiple calls to
     * `_pause` or `_unpause`. Similar to `_actionMultiple`, but rather than
     * supplying an array of addresses, this function takes a range (start and
     * end indexes within the `_registeredAddresses` array).
     *
     * @param start The start index (inclusive).
     * @param end   The end index (exclusive).
     * @param safe  Whether the pause should be called safely.
     *
     * @dev Requirements:
     * -    The contract must support the `NetworkGuardian` interface.
     * -    The supplied range must be valid.
     * -    If `safe` is `true`, the address must not be the zero address.
     * -    If `safe` is `true`, each contract must not already be in the new
     *      desired state.
     */
    function _actionRange(
        Action action,
        uint256 start,
        uint256 end,
        bool safe
    ) private {
        uint256 len = _registeredAddresses.length;
        Array.assertValidRange(start, end, len);

        // end is now known to be greater than, or equal, to start
        uint256 d = end - start;
        if (d > MAX_ITERS) {
            revert NetworkGuardianController__MaxIterations(d, MAX_ITERS);
        }

        uint256 i = start;
        for (i; i < end; i++) {
            if (action == Action.PAUSE) {
                _pause(_registeredAddresses[i], safe);
            } else {
                _unpause(_registeredAddresses[i], safe);
            }
        }
    }
}
