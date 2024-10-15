// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IH1DevelopedApplication
 *
 * @author The Haven1 Development Team
 *
 * @dev The interface for the IH1DevelopedApplication contract.
 */
interface IH1DevelopedApplication {
    /**
     * @notice Emitted when a Developed Application Fee is paid.
     *
     * @param fnSig         The function signature against which the fee was applied.
     * @param feeContract   The fee amount sent to the Fee Contract.
     * @param developer     The fee amount sent to the developer.
     */
    event FeePaid(string indexed fnSig, uint256 feeContract, uint256 developer);

    /**
     * @notice Emitted when a Developed Application Fee is set.
     *
     * @param fnSig     The function signature for which the fee is set.
     * @param fee       The fee that was set.
     */
    event FeeSet(string indexed fnSig, uint256 fee);

    /**
     * @notice Emitted when the Fee Contract address is updated.
     *
     * @param feeContract The address of the new FeeContract.
     */
    event FeeContractAddressUpdated(address indexed feeContract);

    /**
     * @notice Emitted when the Developer address is updated.
     *
     * @param developer The address of the new developer.
     */
    event DeveloperAddressUpdated(address indexed developer);

    /**
     * @notice Emitted when the Developer's Fee Collector address is updated.
     *
     * @param devFeeCollector The address of the new dev fee collector.
     */
    event DevFeeCollectorUpdated(address indexed devFeeCollector);

    /**
     * Emitted when the Developer updates whether this contract stores H1.
     *
     * @param stores The new value.
     */
    event StoresH1Updated(bool stores);

    /**
     * @notice Allows the Developer to set a function fee, within the bounds
     * allowed by the Fee Contract.
     *
     * @param fnSig The function signature.
     * @param fee   The fee.
     *
     * @dev Requirements:
     * -    The fee must be greater than, or equal to, the minimum allowed fee.
     * -    The fee must be less than, or equal to, the maximum allowed fee.
     * -    The fee must be parsed to a precision of 18 decimals.
     * -    Only callable by an account with the role: `DEV_ADMIN_ROLE`.
     *
     * Example Function Signatures:
     * -    "approve(address,uint256)"
     * -    "transfer(address,uint256)"
     * -    "withdraw(uint256)"
     *
     * Example Fees:
     * -    1.75 USD: `1750000000000000000`
     * -    1.00 USD: `1000000000000000000`
     * -    0.50 USD: `500000000000000000`
     *
     * Emits a `FeeSet` event.
     */
    function setFee(string memory fnSig, uint256 fee) external;

    /**
     * @notice Allows the Developer to set a fees on multiple functions, within
     * the bounds allowed by the Fee Contract.
     *
     * @param fnSigs The function signatures.
     * @param fees   The fees.
     *
     * @dev Requirements:
     * -    Each fee must be greater than, or equal to, the minimum allowed fee.
     * -    Each fee must be less than, or equal to, the maximum allowed fee.
     * -    Each fee must be parsed to a precision of 18 decimals.
     * -    Each supplied function signature must have a corresponding fee.
     * -    Only callable by an account with the role: `DEV_ADMIN_ROLE`.
     *
     * Example Function Signatures:
     * -    "approve(address,uint256)"
     * -    "transfer(address,uint256)"
     * -    "withdraw(uint256)"
     *
     * Example Fees:
     * -    1.75 USD: `1750000000000000000`
     * -    1.00 USD: `1000000000000000000`
     * -    0.50 USD: `500000000000000000`
     *
     * Emits `FeeSet` events.
     */
    function setFees(string[] memory fnSigs, uint256[] memory fees) external;

    /**
     * @notice Updates the Fee Contract address.
     *
     * @param feeContract_ The new Fee Contract address.
     *
     * @dev Requirements:
     * -    Only callable by an account with the role: `DEFAULT_ADMIN_ROLE`.
     *
     * Emit a `Association` event.
     */
    function setFeeContract(address feeContract_) external;

    /**
     * @notice Updates the Developer address.
     *
     * @param developer_ The new developer address.
     *
     * @dev Requirements:
     * -    Only callable by an account with the role: `DEFAULT_ADMIN_ROLE`.
     * -    The new developer address must not be the zero address.
     *
     * Emits a `DeveloperAddressUpdated` event.
     */
    function setDeveloper(address developer_) external;

    /**
     * @notice Allows the Developer to update the address to which their fees
     * are sent.
     *
     * @param devFeeCollector_ The new fee collector address.
     *
     * @dev Requirements:
     * -    Only callable by an account with the role: `DEV_ADMIN_ROLE`.
     * -    The new collector address must not be the zero address.
     *
     * Emits a `FeeCollectorUpdated` event.
     */
    function setDevFeeCollector(address devFeeCollector_) external;

    /**
     * @notice Allows the Developer to update whether their contract stores H1.
     *
     * @param stores The new value.
     *
     * @dev Requirements:
     * -    Only callable by an account with the role: `DEFAULT_ADMIN_ROLE`.
     *
     * Emits a `StoresH1Updated` event.
     */
    function setStoresH1(bool stores) external;

    /**
     * @notice Returns the address of the Fee Contract.
     *
     * @return The address of the Fee Contract.
     */
    function feeContract() external view returns (address);

    /*
     * @notice Returns the address of the Developer.
     *
     * @return The address of the Developer.
     */
    function developer() external view returns (address);

    /**
     * @notice Returns the address at which the Developer receives their fees.
     *
     * @return The address at which the Developer receives their fees.
     */
    function devFeeCollector() external view returns (address);

    /**
     * @notice Returns the unadjusted USD fee, if any, associated with the given
     * function selector.
     *
     * @param fnSelector The function selector for which the fee should be
     * retrieved.
     *
     * @return The fee, if any, associated with the given function selector.
     *
     * @dev Example usage: `getFnFee("0xa9059cbb")`
     */
    function getFnFeeUSD(bytes4 fnSelector) external view returns (uint256);

    /**
     * @notice Returns whether this contract stores H1.
     *
     * @return True if this contract stores H1, false otherwise.
     */
    function storesH1() external view returns (bool);

    /**
     * @notice Returns the function selector for a given function signature.
     *
     * @param fnSig The signature of the function.
     *
     * @return The function selector for the given function signature.
     *
     * @dev Example input: `transfer(address,uint256)`
     */
    function getFnSelector(string memory fnSig) external pure returns (bytes4);

    /**
     * @notice Returns the adjusted fee, if any, associated with the given
     * function selector.
     *
     * @param fnSel The function selector for which the fee should be retrieved.
     *
     * @return The adjusted fee, if any, associated with the given function
     * selector.
     *
     * @dev Example input: `getFnFeeAdj("0xa9059cbb")`.
     */
    function getFnFeeAdj(bytes4 fnSel) external view returns (uint256);
}
