// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/**
 * @title RecoverableUpgradeable
 *
 * @notice Allows the inheriting contract to recover H1 and HRC-20s.
 *
 * @dev Note that this contract only exposes functions with internal visibility
 * and does not implement any access control or reentrancy guards. It is up to
 * the inheriting contract to implement these details.
 *
 * @dev This contract does not contain any state variables. Even so, a very
 * small gap has been provided to accommodate the addition of state variables
 * should the need arise.
 */
abstract contract RecoverableUpgradeable is Initializable {
    /* TYPE DECLARATIONS
    ==================================================*/
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* EVENTS
    ==================================================*/
    /**
     * @notice Emitted when H1 is recovered from the contract. Emits the address
     * to which the tokens were sent and the amount of tokens that were sent.
     *
     * @param to The address to which the tokens were sent.
     * @param amount The amount of tokens that were sent.
     */
    event H1Recovered(address indexed to, uint256 amount);

    /**
     * @notice Emitted when an HRC-20 is recovered from the contract. Emits the
     * address of the token that was recovered, the address to which the tokens
     * were sent, and the amount of tokens that were sent.
     *
     * @param token The address of the token recovered.
     * @param to The address to which the tokens were sent.
     * @param amount The amount of tokens that were sent.
     */
    event HRC20Recovered(
        address indexed token,
        address indexed to,
        uint256 amount
    );

    /* ERRORS
    ==================================================*/

    /**
     * @dev Error raised when trying to recover funds to an invalid address.
     */
    error Recoverable__InvalidAddress();

    /**
     * @dev Error raised when the recovery of H1 fails.
     */
    error Recoverable__H1RecoveryFailed();

    /**
     * @dev Error raised when trying to recover zero tokens.
     */
    error Recoverable__ZeroAmountProvided();

    /**
     * @dev Error raised when trying to recover an amount of H1 that exceeds
     * the contract's balance.
     *
     * @param amount The amount attempted to be sent.
     * @param available The amount available to send.
     */
    error Recoverable__InsufficientH1(uint256 amount, uint256 available);

    /**
     * @dev Error raised when trying to recover an amount of an HRC-20 that
     * exceeds the contract's balance.
     * @param token The address of the token.
     * @param amount The amount attempted to be sent.
     * @param available The amount available to send.
     */
    error Recoverable__InsufficientHRC20(
        address token,
        uint256 amount,
        uint256 available
    );

    /* FUNCTIONS
    ==================================================*/
    /* Internal
    ========================================*/
    /**
     * @notice Initializes the `RecoverableUpgradeable` contract.
     */
    function __Recoverable_init() internal onlyInitializing {
        __Recoverable_init_unchained();
    }

    /**
     * @dev see {RecoverableUpgradeable-__Recoverable_init}
     * @dev Although this function contains no init logic, it is included
     * by convention. See the following for further information:
     * https://docs.openzeppelin.com/contracts/5.x/upgradeable#multiple-inheritance
     */
    function __Recoverable_init_unchained() internal onlyInitializing {}

    /**
     * @notice Allows for the recovery of an amount of H1 to a given address.
     * @param to The address to which the H1 will be sent.
     * @param amount The amount of H1 to send.
     *
     * @dev May revert with `Recoverable__InvalidAddress`.
     * @dev May revert with `Recoverable__InsufficientH1`.
     * @dev May revert with `Recoverable__H1RecoveryFailed`.
     * @dev May emit an `H1Recovered` event.
     */
    function _recoverH1(address payable to, uint256 amount) internal {
        if (to == address(0)) {
            revert Recoverable__InvalidAddress();
        }

        if (amount == 0) {
            revert Recoverable__ZeroAmountProvided();
        }

        uint256 bal = address(this).balance;
        if (amount > bal) {
            revert Recoverable__InsufficientH1(amount, bal);
        }

        (bool success, ) = to.call{ value: amount }("");
        if (!success) {
            revert Recoverable__H1RecoveryFailed();
        }

        emit H1Recovered(to, amount);
    }

    /**
     * @notice Allows for the recovery of an amount of an HRC-20 token to a
     * given address.
     *
     * @param token The address of the HRC-20 token to recover.
     * @param to The address to which the tokens will be sent.
     * @param amount The amount of tokens to send.
     *
     * @dev May revert with `Recoverable__InvalidAddress`.
     * @dev May revert with `Recoverable__InsufficientHRC20`.
     * @dev May revert with `SafeERC20: low-level call failed`.
     * @dev May revert with `SafeERC20: ERC20 operation did not succeed`.
     * @dev May emit an `HRC20Recovered` event.
     */
    function _recoverHRC20(address token, address to, uint256 amount) internal {
        if (to == address(0)) {
            revert Recoverable__InvalidAddress();
        }

        if (amount == 0) {
            revert Recoverable__ZeroAmountProvided();
        }

        uint256 bal = IERC20Upgradeable(token).balanceOf(address(this));
        if (amount > bal) {
            revert Recoverable__InsufficientHRC20(token, amount, bal);
        }

        IERC20Upgradeable(token).safeTransfer(to, amount);

        emit HRC20Recovered(token, to, amount);
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
     * (256 bits in size or part thereof), the gap must now be reduced to `24`.
     */
    uint256[25] private __gap;
}
