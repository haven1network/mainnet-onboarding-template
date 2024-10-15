// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IRecoverable
 * @dev The interface for the Recoverable contract.
 */
interface IRecoverable {
    /**
     * @notice Allows the recovery of an amount of H1 to a given address.
     * @param to The address to send the H1 to.
     * @param amount The amount of H1 to send.
     */
    function recoverH1(address payable to, uint256 amount) external;

    /**
     * @notice Allows the recovery of all of this contract' H1 to a given address.
     * @param to The address to send the H1 to.
     */
    function recoverAllH1(address to) external;

    /**
     * @notice Allows the recovery of an amount of an HRC20 to a given address.
     * @param token The address of the HRC20 token to recover.
     * @param to The address to send the recovered tokens to.
     * @param amount The amount of tokens to recover.
     */
    function recoverHRC20(address token, address to, uint256 amount) external;

    /**
     * @notice Allows the recovery of this contract's balance of an HRC20 to a
     * given address.
     * @param token The address of the HRC20 token to recover.
     * @param to The address to send the recovered tokens to.
     */
    function recoverAllHRC20(address token, address to) external;
}
