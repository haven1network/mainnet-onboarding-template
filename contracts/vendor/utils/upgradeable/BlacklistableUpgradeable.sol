// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { Address } from "../Address.sol";
import { IProofOfIdentity } from "../../proof-of-identity/interfaces/IProofOfIdentity.sol";

/**
 * @title BlacklistableUpgradeable
 *
 * @author The Haven1 Development Team
 *
 * @dev This contract provides the ability to blacklist addresses.
 *
 * It exposes a `bypassBlacklist` modifier that can be attached to functions
 * that should initiate skipping the blacklist check. Only one function in the
 * call chain can initiate a blacklist bypass. Subsequent calls to
 * `bypassBlacklist` will be treated as reentrancy and will revert.
 *
 *
 * It is up to the developer to compose calls to `_isBypassingBlacklist` or
 * `_assertNotBlacklisted` to achieve the desired result depending on their use
 * case.
 *
 * When an address is added to, or removed from, the blacklist, so too are all
 * of that address' associated accounts (accounts linked via the Proof of
 * Identity contract).
 */
abstract contract BlacklistableUpgradeable is Initializable {
    /* TYPE DECLARATIONS
    ==================================================*/
    using Address for address;

    /* STATE
    ==================================================*/
    /**
     * @dev Indicates the blacklist is not currently being bypassed.
     */
    uint256 private constant _NOT_BYPASSED = 1;

    /**
     * @dev Indicates the blacklist is currently being bypassed.
     */
    uint256 private constant _BYPASSED = 2;

    /**
     * @dev The current bypass state. Either:
     * -    `_NOT_BYPASSED`; or
     * -    `_BYPASSED`.
     */
    uint256 private _status;

    /**
     * @dev Maps an address to its blacklist status.
     */
    mapping(address => bool) private _blacklist;

    /**
     * @dev The Proof of Identity contract address.
     */
    IProofOfIdentity private _poi;

    /* EVENTS
    ==================================================*/
    /**
     * Emitted when an account is blacklisted.
     *
     * @param account The account that was blacklisted.
     */
    event Blacklisted(address indexed account);

    /**
     * Emitted when an account has its blacklist removed.
     *
     * @param account The account that had its blacklist removed.
     */
    event BlacklistRemoved(address indexed account);

    /* ERRORS
    ==================================================*/

    /**
     * @dev Raised when an invalid attempt is made to blacklist an account.
     *
     * @param addr The account to blacklist.
     */
    error Blacklistable__IsBlacklisted(address addr);

    /**
     * @dev Raised when an invalid attempt is made to remove an account's
     * blacklist.
     *
     * @param addr The account to have the blacklist removed.
     */
    error Blacklistable__IsNotBlacklisted(address addr);

    /**
     * @dev Raised when a reentrant call is made.
     */
    error Blacklistable__ReentrantCall();

    /**
     * @dev Raised when an attempt was made to bypass the blacklist in excess of
     * the points available.
     */
    error Blacklistable__BypassesExceeded();

    /* MODIFIERS
    ==================================================*/

    /**
     * @notice Modifier that allows the blacklist to be bypassed.
     *
     * @dev Requirements:
     * -    The contract must not already be in a bypassing state.
     */
    modifier bypassBlacklist() {
        _bypassBlacklistBefore();
        _;
        _bypassBlacklistAfter();
    }

    /**
     * @dev Modifier that checks a given address is not blacklisted.
     */
    modifier whenNotBlacklisted(address addr) {
        _assertNotBlacklisted(addr);
        _;
    }

    /* FUNCTIONS
    ==================================================*/
    /* Init
    ========================================*/
    function __Blacklistable_init(
        address proofOfIdentity
    ) internal onlyInitializing {
        __Blacklistable_init_unchained(proofOfIdentity);
    }

    function __Blacklistable_init_unchained(
        address proofOfIdentity
    ) internal onlyInitializing {
        proofOfIdentity.assertNotZero();

        _poi = IProofOfIdentity(proofOfIdentity);
        _status = _NOT_BYPASSED;
    }

    /* Public
    ========================================*/
    /**
     * @notice Returns whether a given address is blacklisted.
     *
     * @param addr The address to check.
     */
    function blacklisted(address addr) public view returns (bool) {
        return _isBlacklisted(addr);
    }

    /* Internal
    ========================================*/

    /*
     * @notice Blacklists an address.
     *
     * @param addr The address to blacklist.
     *
     * @dev Requirements:
     * -    The address must not be the zero address.
     *
     * Emits a `Blacklisted` event.
     */
    function _addToBlacklist(address addr) internal {
        // We are blacklisting the principal account, so any auxilliary accounts
        // will be blacklisted as well.

        addr.assertNotZero();

        address principal = _poi.principalAccount(addr);
        if (principal == address(0)) {
            // principal could be zero if the user has no POI
            if (!_blacklist[addr]) {
                _blacklist[addr] = true;
                emit Blacklisted(addr);
            }
            return;
        }

        if (!_blacklist[principal]) {
            _blacklist[principal] = true;
            emit Blacklisted(principal);
        }
    }

    /*
     * @notice Removes an address' blacklist.
     *
     * @param addr The address to blacklist.
     *
     * @dev Requirements:
     * -    The address must not be the zero address.
     *
     * Emits a `BlacklistRemoved` event.
     */
    function _removeFromBlacklist(address addr) internal {
        // Removing the principal account, so any auxilliary accounts will be
        // unlocked as well.

        addr.assertNotZero();
        address principal = _poi.principalAccount(addr);

        // Remove the provided address from the blacklist.
        // This is for the edge case that a user got banned while not having a POI.
        if (_blacklist[addr]) {
            _blacklist[addr] = false;
            emit BlacklistRemoved(addr);
        }

        if (principal != address(0) && _blacklist[principal]) {
            _blacklist[principal] = false;
            emit BlacklistRemoved(principal);
        }
    }

    /**
     * @notice Returns whether a given address is blacklisted.
     *
     * @param addr The address to check.
     *
     * @return True if the address has been blacklisted, false otherwise.
     */
    function _isBlacklisted(address addr) internal view returns (bool) {
        if (addr == address(0)) return false;

        address principal = _poi.principalAccount(addr);
        if (principal == address(0)) {
            return _blacklist[addr];
        }

        return _blacklist[principal];
    }

    /**
     * @notice Indicates whether the blacklist is currently being bypassed.
     *
     * @return True if the blacklist is being bypassed, false otherwise.
     */
    function _isBypassingBlacklist() internal view returns (bool) {
        return _status == _BYPASSED;
    }

    /**
     * @notice Asserts that the given address is not on the blacklist.
     *
     * @dev Will revert if the address is on the blacklist.
     */
    function _assertNotBlacklisted(address addr) internal view {
        if (_isBlacklisted(addr)) {
            revert Blacklistable__IsBlacklisted(addr);
        }
    }

    /* Private
    ========================================*/

    /**
     * @notice Executes logic before allowing the blacklist to be bypassed.
     *
     * @dev Requirements:
     * -    The contract must not already be in a bypassing state.
     */
    function _bypassBlacklistBefore() private {
        if (_isBypassingBlacklist()) {
            revert Blacklistable__ReentrantCall();
        }

        _status = _BYPASSED;
    }

    /**
     * @notice Executes logic after the blacklist has been bypassed.
     */
    function _bypassBlacklistAfter() private {
        _status = _NOT_BYPASSED;
    }

    /* Gap
    ========================================*/
    /**
     * @dev This empty reserved space allows new state variables to be added
     * without compromising the storage compatibility with existing deployments.
     *
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     *
     * As new variables are added, be sure to reduce the gap as required.
     * For e.g., if the starting `__gap` is `25` and a new variable is added
     * (256 bits in size or part thereof), the gap must now be reduced to `24`.
     */
    uint256[25] private __gap;
}
