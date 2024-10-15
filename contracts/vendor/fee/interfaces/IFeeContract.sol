// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IFeeContract
 *
 * @author The Haven1 Development Team
 *
 * @dev The interface for the FeeContract.
 */
interface IFeeContract {
    /**
     * @notice Emitted when fees are received into the contract.
     *
     * @param from      The source address.
     * @param txOrigin  The origin of the transaction.
     * @param amount    The amount of fees received.
     */
    event FeesReceived(
        address indexed from,
        address indexed txOrigin,
        uint256 amount
    );

    /**
     * @notice Emitted when fees are distributed from the contract.
     *
     * @param to        The destination address.
     * @param amount    The amount of fees distributed.
     */
    event FeesDistributed(address indexed to, uint256 amount);

    /**
     * @notice Emitted when the fee is updated.
     *
     * @param newFee The new fee amount.
     */
    event FeeUpdated(uint256 newFee);

    /**
     * @notice Emitted when a new distribution channel is added to the contract.
     *
     * @param newChannelAddress     The address of the new channel.
     * @param channelWeight         The weight of the new channel.
     * @param contractShares        The total shares of the contract.
     */
    event ChannelAdded(
        address indexed newChannelAddress,
        uint256 channelWeight,
        uint256 contractShares
    );

    /**
     * @notice Emitted when an existing distribution channel is adjusted.
     *
     * @param adjustedChannel       The address of the adjusted channel.
     * @param newChannelWeight      The address of the adjusted channel.
     * @param currentContractShares The current contract shares.
     */
    event ChannelAdjusted(
        address indexed adjustedChannel,
        uint256 newChannelWeight,
        uint256 currentContractShares
    );

    /**
     * @notice Emitted when a distribution channel is removed from the contract.
     *
     * @param channelRemoved        The channel that was removed.
     * @param newTotalSharesAmount  The total shares of the contract.
     */
    event ChannelRemoved(
        address indexed channelRemoved,
        uint256 newTotalSharesAmount
    );

    /**
     * @notice Emitted when the minimum developer fee is updated.
     *
     * @param newFee The new minimum fee.
     */
    event MinFeeUpdated(uint256 newFee);

    /* @notice Emitted when the maximum developer fee is updated.
     *
     * @param newFee The new maximum fee.
     */
    event MaxFeeUpdated(uint256 newFee);

    /**
     * @notice Emitted when the H1 oracle address is updated.
     *
     * @param prev The previous oracle address.
     * @param curr The new oracle address.
     */
    event OracleUpdated(address prev, address curr);

    /**
     * @notice Emitted when the fee epoch length is updated.
     *
     * @param epoch The new epoch length.
     */
    event FeeEpochUpdated(uint256 epoch);

    /**
     * @notice Emitted when the distribution epoch length is updated.
     *
     * @param epoch The new distribution epoch length.
     */
    event DistributionEpochUpdated(uint256 epoch);

    /**
     * @notice Emitted when an EOA is set up to skip the fee collection.
     *
     * @param eoa       The address that is set up to skip fee collection.
     * @param skipFee   Whether skipping the fee was enabled or disabled.
     */
    event ExemptEOAUpdated(address indexed eoa, bool indexed skipFee);

    /**
     * @notice Emitted when a new grace period is set.
     *
     * @param period The new grace period, in seconds.
     */
    event GracePeriodUpdated(uint256 period);

    /**
     * @notice Emitted when a caller's fee exemption status on a certain contract
     * is updated.
     *
     * @param contractAddr  The address of the contract.
     * @param caller        The address of the caller.
     * @param skipFee       Whether skipping the fee was enabled or disabled.
     */
    event ExemptCallerUpdated(
        address indexed contractAddr,
        address indexed caller,
        bool indexed skipFee
    );

    /**
     * @notice Emitted when the fee exemption status of a function on a contract
     * is updated.
     *
     * @param contractAddr  The address of the contract.
     * @param fnSel         The function selector.
     * @param skipFee       Whether skipping the fee was enabled or disabled.
     */
    event ExemptFunctionUpdated(
        address indexed contractAddr,
        bytes4 indexed fnSel,
        bool indexed skipFee
    );

    /**
     * @notice Emitted when a contract's fee exemption status is updated.
     *
     * @param contractAddr  The address of the contract.
     * @param skipFee       Whether skipping the fee was enabled or disabled.
     */
    event ExemptContractUpdated(
        address indexed contractAddr,
        bool indexed skipFee
    );

    /**
     * @notice Adds a new distribution channel.
     *
     * @param channel_  The address of the new channel.
     * @param weight_   The weight of the new channel.
     *
     * @dev Requirements:
     * -    The caller must have the role: `OPERATOR_ROLE`.
     * -    The current amount of channels must be less than ten.
     *
     * Emits a `ChannelAdded` event.
     */
    function addChannel(address channel_, uint256 weight_) external;

    /**
     * @notice Adjusts a channel and its weight.
     *
     * @param prevChannel_  The address of the channel to update.
     * @param newChannel_   The address of the channel that replaces the old one.
     * @param weight_       The amount of shares the new address will receive.
     *
     * @dev Requirements:
     * -    The caller must have the role: `OPERATOR_ROLE`.
     * -    The new channel address must not be the zero address and must be
     *      unique among the existing channels.
     * -    The weight must not be zero.
     * -    The channel that is being replaced must exist.
     *
     * Emits a `ChannelAdjusted` event.
     */
    function adjustChannel(
        address prevChannel_,
        address newChannel_,
        uint256 weight_
    ) external;

    /**
     * @notice Adjusts the weight associated with a given channel.
     *
     * @param channel_  The address of the channel to update.
     * @param weight_   The amount of shares the new address will receive.
     *
     * @dev Requirements:
     * -    The caller must have the role: `OPERATOR_ROLE`.
     * -    The weight must not be zero.
     * -    The channel that is being updated must exist.
     *
     * Emits a `ChannelAdjusted` event.
     */
    function adjustChannelWeight(address channel_, uint256 weight_) external;

    /**
     * @notice Removes a channel and its weight.
     *
     * @param channel_ The address being removed.
     *
     * @dev Requirements:
     * -    The caller must have the role: `OPERATOR_ROLE`.
     * -    The channel must exist.
     *
     * Emits a `ChannelRemoved` event.
     */
    function removeChannel(address channel_) external;

    /**
     * @notice Distributes fees to channels.
     *
     * @dev Requirements:
     * -    Enough time must have passed since the last distribution .
     *
     * Emits a `FeesDistributed` event.
     */
    function distributeFees() external;

    /**
     * @notice Forces a fee distribution.
     *
     * @dev Requirements:
     * -    The caller must have the role: `OPERATOR_ROLE`.
     *
     * Emits a `FeesDistributed` event.
     */
    function forceDistributeFees() external;

    /**
     * @notice Updates the H1 application fee, the H1 USD price, and associated
     * values.
     *
     * @dev This function can be called by anyone. H1 Developed and Native
     * Application contracts will also call this function.
     *
     * Emits a `FeeUpdated` event.
     */
    function updateFee() external;

    /**
     * @notice Sets the minimum fee, in USD, for developer applications.
     *
     * @param fee_ The minimum fee, in USD, that a developer may charge.
     *
     * @dev Requirements:
     * -    The caller must have the role: `OPERATOR_ROLE`.
     * -    Must be to a precision of 18 decimals.
     * -    Must be less than, or equal to, the maximum fee.
     *
     * Emits a `MinFeeUpdated` event.
     */
    function setMinFee(uint256 fee_) external;

    /**
     * @notice Sets the maximum fee, in USD, for developer applications.
     *
     * @param fee_ The maximum fee, in USD, that a developer may charge.
     *
     * @dev Requirements:
     * -    The caller must have the role: `OPERATOR_ROLE`.
     * -    Must be to a precision of 18 decimals.
     * -    Must be greater than, or equal to, the minimum fee.
     *
     * Emits a `MaxFeeUpdated` event.
     */
    function setMaxFee(uint256 fee_) external;

    /**
     * @notice Sets the oracle address.
     *
     * @param addr_ The new oracle address.
     *
     * @dev Requirements:
     * -    The caller must have the role: `OPERATOR_ROLE`.
     * -    The new address must not be the zero address.
     *
     * Emits an `OracleUpdated` event.
     */
    function setOracle(address addr_) external;

    /**
     * @notice Sets the grace period.
     *
     * @param period_ The new grace period, in seconds.
     *
     * @dev Requirements:
     * -    The caller must have the role: `OPERATOR_ROLE`.
     * -    The new period must not exceed the Fee Update Epoch.
     *
     * Emits a `GracePeriodUpdated` event.
     */
    function setGracePeriod(uint256 period_) external;

    /**
     * @notice Updates the caller's grace contract status.
     *
     * @param status_ Whether to set the `msg.sender` as a grace contract.
     */
    function setGraceContract(bool status_) external;

    /**
     * @notice Updates the fee exemption status for a given address.
     *
     * @param eoa_       The address of the EOA.
     * @param skipFee_   The exemption status.
     *
     * @dev Requirements:
     * -    The caller must have the role: `OPERATOR_ROLE`.
     * -    The address provided must be an EOA.
     *
     * Emits an `ExemptEOAUpdated` event.
     */
    function setExemptEOA(address eoa_, bool skipFee_) external;

    /**
     * @notice Updates the fee exemption status for a given caller and contract
     * pair.
     *
     * @param contract_ The address of the contract.
     * @param caller_   The address of the caller.
     * @param skipFee_  The exemption status.
     *
     * @dev Requirements:
     * -    The caller must have the role: `OPERATOR_ROLE`.
     *
     * Emits an `ExemptCallerUpdated` event.
     */
    function setExemptCaller(
        address contract_,
        address caller_,
        bool skipFee_
    ) external;

    /**
     * @notice Updates the fee exemption status of a function on a specific contract.
     *
     * @param contract_ The address of the contract.
     * @param fnSel_    The function selector.
     * @param skipFee_  The exemption status.
     *
     * @dev Requirements:
     * -    The caller must have the role: `OPERATOR_ROLE`.
     *
     * Emits an `ExemptFunctionUpdated` event.
     */
    function setExemptFunction(
        address contract_,
        bytes4 fnSel_,
        bool skipFee_
    ) external;

    /**
     * @notice Updates the fee exemption status of an entire contract.
     *
     * @param contract_ The address of the contract.
     * @param skipFee_  The exemption status.
     *
     * @dev Requirements:
     * -    The caller must have the role: `OPERATOR_ROLE`.
     *
     * Emits an `ExemptContractUpdated` event.
     */
    function setExemptContract(address contract_, bool skipFee_) external;

    /**
     * @notice Updates the USD value of the application fee.
     *
     * @param feeUSD_ The new fee, in USD, to a precision of 18 decimals.
     *
     * @dev Requirements:
     * -    The caller must have the role: `OPERATOR_ROLE`.
     * -    The fee must be to a precision of 18 decimals.
     *
     * Examples:
     * -    1.75 USD: `1750000000000000000`
     * -    1.00 USD: `1000000000000000000`
     * -    0.50 USD: `500000000000000000`
     */
    function setFeeUSD(uint256 feeUSD_) external;

    /**
     * @notice Updates the Association's share of the developer fee.
     *
     * @param assocShare_ The Association's new share of the developer fee.
     *
     * @dev Requirements:
     * -    The caller must have the role: `OPERATOR_ROLE`.
     * -    The share must be to a precision of 18 decimals.
     *
     * Example:
     * -    10%: `100000000000000000`
     * -    15%: `150000000000000000`
     */
    function setAssocShare(uint256 assocShare_) external;

    /**
     * @notice Adjusts how often the fee value can be updated.
     *
     * @param secs_ The amount of time, in seconds, that must pass between fee updates.
     *
     * @dev Requirements:
     * -    The caller must have the role: `OPERATOR_ROLE`.
     *
     * Emits a `FeeEpochUpdated` event.
     */
    function setFeeUpdateEpoch(uint256 secs_) external;

    /**
     * @notice Adjusts how frequently a fee distribution can occur.
     *
     * @param secs_ The amount of time, in seconds, that must pass between fee distributions.
     *
     * @dev Requirements:
     * -    The caller must have the role: `OPERATOR_ROLE`.
     *
     * Emits a `DistributionEpochUpdated` event.
     */
    function setDistributionEpoch(uint256 secs_) external;

    /**
     * @notice Returns the current application fee value, in USD, to a precision
     * of 18 decimals.
     *
     * @return The current fee value, in USD, to a precision of 18 decimals.
     *
     * @dev Note that this function will only check if the caller is exempt from
     * paying the fee. To check if a combination of contract, function selector
     * and caller are exempt, please see: `getFeeForContract`.
     */
    function getFeeUSD() external view returns (uint256);

    /**
     * @notice Returns the Association's share of the developer fee to a
     * precision of 18 decimals.
     *
     * @return The Association's share of the developer fee to a precision of
     * 18 decimals.
     */
    function getAssocShare() external view returns (uint256);

    /**
     * @notice Returns the timestamp at which the next fee update can occur.
     *
     * @return The timestamp at which the next fee update can occur.
     */
    function nextResetTime() external view returns (uint256);

    /**
     * @notice Returns the amount of time, in seconds, that must pass between
     * fee distributions.
     *
     * @return The amount of time, in seconds, that must pass between fee
     * distributions.
     */
    function getDistributionEpoch() external view returns (uint256);

    /**
     * @notice Returns the amount of time, in seconds, that must pass between
     * fee updates.
     *
     * @return The amount of time, in seconds, that must pass between fee updates.
     */
    function getFeeUpdateEpoch() external view returns (uint256);

    /**
     * @notice Returns the fee associated with a specific contract call.
     *
     * @param contract_ The address of the contract with the application fee.
     * @param caller_   The address of the caller.
     * @param fnSel_    The selector of the function being invoked.
     *
     * @return The fee for the specific contract call.
     *
     * @dev Contexts considered:
     * -    Whether the `contract_` is exempt from fees.
     * -    Whether the combination of `contract_` and `caller_` is exempt from fees.
     * -    Whether the combination of `contract_` and `fnSel_` is exempt from fees.
     * -    Otherwise, delegates fee calculation to `getFee()`.
     */
    function getFeeForContract(
        address contract_,
        address caller_,
        bytes4 fnSel_
    ) external view returns (uint256);

    /**
     * @notice Returns how many H1 tokens equal one (1) USD, in a context aware
     * manner.
     *
     * @return How many H1 tokens equal one (1) USD, in a context aware manner.
     *
     * @dev Contexts considered:
     * -    Whether the caller is a "Grace Contract".
     */
    function h1USD() external view returns (uint256);

    /**
     * @notice Returns an array of all the channel addresses.
     *
     * @return An array of all the channel addresses.
     */
    function getChannels() external view returns (address[] memory);

    /**
     * @notice Returns an array of all the channel weights.
     *
     * @return An array of all the channel weights.
     */
    function getWeights() external view returns (uint256[] memory);

    /**
     * @notice Returns the fee oracle address.
     *
     * @return The fee oracle address.
     */
    function getOracleAddress() external view returns (address);

    /**
     * @notice Returns a channel's address and its weight.
     *
     * @param index The index in the array of channels/weights.
     *
     * @return The channel's address.
     * @return The channel's weight.
     */
    function getChannelWeightByIndex(
        uint8 index
    ) external view returns (address, uint256);

    /**
     * @notice Returns the total contract shares.
     *
     * @return The total contract shares.
     */
    function getTotalContractShares() external view returns (uint256);

    /**
     * @notice Returns the timestamp of the most recent fee distribution.
     *
     * @return The timestamp of the most recent fee distribution.
     */
    function getLastDistribution() external view returns (uint256);

    /**
     * @notice Returns the minimum fee, in USD, that a developer may charge.
     *
     * @return The minimum fee, in USD, that a developer may charge.
     */
    function getMinDevFee() external view returns (uint256);

    /**
     * @notice Returns the maximum fee, in USD, that a developer may charge.
     *
     * @return The maximum fee, in USD, that a developer may charge.
     */
    function getMaxDevFee() external view returns (uint256);

    /**
     * @notice Returns the amount of fees that will be sent to a channel upon
     * the next fee distribution.
     *
     * @param index The index of the channel in the `_channel` array.
     *
     * @return The intended fee.
     */
    function nextDistributionAmount(
        uint8 index
    ) external view returns (uint256);

    /**
     * @notice Returns the current grace period length, in seconds.
     *
     * @return The current grace period length, in seconds.
     */
    function getGracePeriod() external view returns (uint256);

    /**
     * @notice Returns if a given address is registered as a grace contract.
     *
     * @param addr_ The address to check.
     *
     * @return True if the contract is registered, false otherwise.
     */
    function isGraceContract(address addr_) external view returns (bool);

    /**
     * @notice Returns if any combination of contract address, function
     * selector, and caller address is exempt from paying fees.
     *
     * @param contract_ The address of the contract.
     * @param fnSel_    The function selector.
     * @param caller_   The address of the caller.
     *
     * @return True if any combination of the inputs are exempt from fees, false
     * otherwise.
     */
    function isExempt(
        address contract_,
        bytes4 fnSel_,
        address caller_
    ) external view returns (bool);

    /**
     * @notice Returns the current application fee, in a context aware manner.
     *
     * @return The current fee.
     *
     * @dev Contexts considered:
     * -    Whether the transaction origin is exempt from fees.
     * -    Whether the caller is a "Grace Contract".
     */
    function getFee() external view returns (uint256);

    /**
     * @notice Returns one (1) USD worth of H1.
     *
     * @return One (1) USD worth of H1.
     */
    function queryOracle() external view returns (uint256);

    /**
     * @notice Returns the fee exemption status for an EOA.
     *
     * @param addr_ The address to check.
     *
     * @return True if the address is an EOA that is exempt, false otherwise.
     */
    function isExemptEOA(address addr_) external view returns (bool);

    /**
     * @notice Returns the fee exemption status for a given caller and contract
     * pair.
     *
     * @param contract_ The address of the contract.
     * @param caller_   The address of the caller.
     *
     * @return True if the caller and contract pair is exempt from fees, false
     * otherwise.
     */
    function isExemptCaller(
        address contract_,
        address caller_
    ) external view returns (bool);

    /**
     * @notice Returns the fee exemption status for a given contract and function
     * selector pair.
     *
     * @param contract_ The address of the contract.
     * @param fnSel_    The function selector.
     *
     * @return True if the contract and function selector pair is exempt from
     * fees, false otherwise.
     */
    function isExemptFunction(
        address contract_,
        bytes4 fnSel_
    ) external view returns (bool);

    /**
     * @notice Returns the fee exemption status for a given contract.
     *
     * @param contract_ The address of the contract.
     *
     * @return True if the contract is exempt from fees, false otherwise.
     */
    function isExemptContract(address contract_) external view returns (bool);
}
