// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { H1DevelopedApplication } from "../../vendor/h1-developed-application/H1DevelopedApplication.sol";

/**
 * @title SimpleStorage
 *
 * @author The Haven1 Development Team
 *
 * @notice A Simple Storage contract that demonstrates a minimal implementation
 * of, and interaction with, the `H1DevelopedApplication` contract.
 *
 * @dev As noted as a requirement in the `H1DevelopedApplication` documentation,
 * all public and external functions that modify state have both the
 * `whenNotGuardianPaused` and `developerFee` modifiers applied.
 *
 * As this contract does not store native H1, it marks `storesH1` as `false` and
 * opts to refund users any excess H1 they send in to pay fees.
 */
contract SimpleStorage is H1DevelopedApplication {
    /* TYPE DECLARATIONS
    ==================================================*/
    enum Direction {
        DECR,
        INCR,
        RESET
    }

    /* STATE VARIABLES
    ==================================================*/
    uint256 private _count;

    /* EVENTS
    ==================================================*/
    /**
     * @notice Emitted when the count is updated.
     *
     * @param addr  The address that incremented the count.
     * @param dir   The count direction.
     * @param count The new count.
     * @param fee   The fee paid.
     */
    event Count(
        address indexed addr,
        Direction indexed dir,
        uint256 count,
        uint256 fee
    );

    /* FUNCTIONS
    ==================================================*/
    /* Constructor
    ========================================*/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /* Initialize
    ========================================*/

    /**
     * @notice Initializes the `SimpleStorage` contract.
     *
     * @param feeContract           The Fee Contract address.
     * @param guardianController    The Network Guardian Controller address.
     * @param association           The Haven1 Association address.
     * @param developer             The address of the contract's developer.
     * @param feeCollector          The address of the developer's fee collector.
     * @param fnSigs                Function signatures for which fees will be set.
     * @param fnFees                Fees that will be set for their `fnSigs` counterparts.
     * @param storesH1              Whether this contract stores native H1.
     */
    function initialize(
        address feeContract,
        address guardianController,
        address association,
        address developer,
        address feeCollector,
        string[] memory fnSigs,
        uint256[] memory fnFees,
        bool storesH1
    ) external initializer {
        __H1DevelopedApplication_init(
            feeContract,
            guardianController,
            association,
            developer,
            feeCollector,
            fnSigs,
            fnFees,
            storesH1
        );
    }

    /* External
    ========================================*/

    /**
     * @notice Increments the count by one.
     *
     * @dev Requirements:
     * -    The contract must not be paused.
     * -    The correct fee must be supplied.
     *
     * Emits a `Count` event.
     */
    function incrementCount()
        external
        payable
        whenNotGuardianPaused
        developerFee(false, true)
    {
        _count++;
        uint256 fee = getFnFeeAdj(msg.sig);
        emit Count(msg.sender, Direction.INCR, _count, fee);
    }

    /**
     * @notice Decrements the count by one.
     *
     * @dev Requirements:
     * -    The contract must not be paused.
     * -    The correct fee must be supplied.
     *
     * Emits a `Count` event.
     */
    function decrementCount()
        external
        payable
        whenNotGuardianPaused
        developerFee(false, true)
    {
        if (_count > 0) {
            _count--;
        }

        uint256 fee = getFnFeeAdj(msg.sig);
        emit Count(msg.sender, Direction.DECR, _count, fee);
    }

    /**
     * @notice Allows the developer to reset the count.
     *
     * @dev Requirements:
     * -    Only callable by an account with the role: `DEV_ADMIN_ROLE`.
     * -    The contract must not be paused.
     * -    The correct fee must be supplied.
     *
     * Emits a `Count` event.
     */
    function resetCount()
        external
        payable
        whenNotGuardianPaused
        developerFee(false, true)
        onlyRole(DEV_ADMIN_ROLE)
    {
        _count = 0;
        uint256 fee = getFnFeeAdj(msg.sig);
        emit Count(msg.sender, Direction.RESET, _count, fee);
    }

    /**
     * @notice Retruns the current count.
     *
     * @return The current count.
     */
    function count() external view returns (uint256) {
        return _count;
    }
}

