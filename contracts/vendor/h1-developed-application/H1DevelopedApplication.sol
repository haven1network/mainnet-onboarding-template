// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IFeeContract } from "../fee/interfaces/IFeeContract.sol";
import { NetworkGuardian } from "../network-guardian/NetworkGuardian.sol";
import { Address } from "../utils/Address.sol";

import { FnSig } from "./lib/FnSig.sol";
import { IH1DevelopedApplication } from "./interfaces/IH1DevelopedApplication.sol";
import "./lib/Errors.sol";

/**
 * @title H1DevelopedApplication
 *
 * @author The Haven1 Development Team
 *
 * @dev
 *
 * # Overview
 *
 * Haven1 is an EVM-compatible Layer 1 blockchain that seamlessly incorporates
 * key principles of traditional finance into the Web3 ecosystem. On Haven1, all
 * contracts will be submitted to the Haven1 Association for review before
 * deployment. Upon successful review, the Haven1 Association will deploy the
 * contract on behalf of the developer. This process ensures a) that all
 * contracts adhere to the standards set by Haven1 and b) will have undergone
 * scrutiny for security and functionality before being deployed on the network.
 *
 * To aid in the developer experience, Haven1 have authored this contract - the
 * `H1DevelopedApplication` contract. All third-party contracts deployed to the
 * network must implement this contract.
 *
 * `H1DevelopedApplication` is an abstract contract that serves as the entry point
 * into the Haven1 ecosystem. It, in essence, standardizes aspects of the contract
 * deployment and upgrade process, provides an avenue for developers to set
 * function-specific fees, establishes contract privileges and ensures the
 * interoperability and compatibility of the contract within the broader ecosystem.
 *
 * ## Core Privileges
 *
 * This contract implements Open Zeppelin's `AccessControl` to establish
 * privileges on the contract. It establishes the following key roles:
 *
 * -   DEFAULT_ADMIN_ROLE:  Assigned to the Haven1 Association.
 * -   OPERATOR_ROLE:       Assigned to the Haven1 Association.
 * -   NETWORK_GUARDIAN:    Assigned to the Haven1 Association and the Network Guardian Controller contract.
 * -   DEV_ADMIN_ROLE:      Assigned to the developer of the application.
 *
 * ## Network Guardian
 *
 * This contract implements Haven1's `NetworkGuardian` contract. It, in essence,
 * allows accounts with the role `NETWORK_GUARDIAN` to pause and resume operation
 * of the contract - a crucial feature necessary for responding to emergency
 * situations.
 *
 * The `whenNotGuardianPaused` modifier that is exposed by `NetworkGuardian` must
 * also be attached to any public or external functions that modify state.
 *
 * While similar in nature to Open Zeppelin's `Pausable` contract, Haven1's
 * `NetworkGuardian` contract provides an entirely separate API and does not
 * collide with any namespaces from `Pausable`. This means that developers are
 * free to import and use Open Zeppelin's `Pausable` contract as they see fit.
 *
 * ## Contract Upgrading
 *
 * This contract implements Open Zeppelin's `UUPSUpgradeable` and `Initializable`
 * contracts to establish the ability to upgrade the contract. Only the Haven1
 * Association, by virtue of the roles outlined above, will have the ability to
 * upgrade a contract.
 *
 * Contracts built on Haven1 must be compatible with the upgrade strategy.
 *
 * ## Function Fees
 *
 * The account with the role `DEV_ADMIN_ROLE` is able to assign function-specific
 * fees via `setFee` and `setFees`. If a function has not been assigned a fee,
 * the minimum fee provided by the `FeeContract` will be applied to the
 * transaction. The unadjusted USD fee value of a given function can be viewed
 * with `getFnFeeUSD`. The adjusted fee in H1 tokens can be viewed with
 * `getFnFeeAdj`.
 *
 * This contract exposes a modifier - `developerFee` - that is to be attached to
 * any public or external function that modifies state. All developer fees in
 * the Haven1 ecosystem are taken in the network's native H1 token. This means
 * functions that attach the `developerFee` modifier will need to be marked as
 * payable. Functions that ordinarily rely on `msg.value` will now use the
 * internal function `msgValueAfterFee` to retrieve the remaining `msg.value`
 * after the fee has been deducted.
 *
 * The modifier defines two parameters:
 * -    `payableFunction`: Indicates if the function would have been `payable`
 *      if not for the modifier. If true, the `msg.value` will be reduced by the
 *      payable fee, and developers will use the `msgValueAfterFee` function to
 *      retrieve the adjusted `msg.value`. If false, it is assumed that
 *      `msg.value` will not be used and no adjustments will be made.
 *
 * -    `refundRemainingBalance`: Controls whether any remaining balance after
 *      function execution should be refunded to the caller. This should __not__
 *      be enabled in contracts that store H1 tokens, as it will inadvertently
 *      transfer the contract's balance to the user.
 *
 * During contract initialization, developers will select whether the contract
 * stores native H1. As a safety measure, if `_storesH1` is marked as `true`, the
 * `developerFee` modifier _will not_ refund H1 to the user, even if it is set to
 * via `refundRemainingBalance`. The developer can request the Haven1 Association
 * to modify the value assigned to `_storesH1`.
 *
 * Note also that the `developerFee` modifier does not allow reentrant calls.
 * Functions marked as `developerFee` may not call one another. In situations
 * where this is required, composing private functions and exposing a single
 * `external` entry point is recommended.
 *
 * ## Example
 *
 * ```solidity
 *
 *   function incrementCount()
 *       external
 *       payable
 *       whenNotGuardianPaused
 *       developerFee(true, false)
 *   {
 *       _count++;
 *
 *       // Do something with the adjusted message value:
 *       _excess[msg.sender] = msgValueAfterFee();
 *
 *       emit Count(msg.sender, Direction.INCR, _count);
 *   }
 * ```
 *
 * # Contract Initialization
 *
 * Initializing a contract that implements `H1DevelopedApplication` is an easy
 * process. The `initialize` function in your contract simply needs to call
 * `__H1DevelopedApplication_init` and provide the required arguments.
 *
 * After contract initialization, the `register` function must be called to
 * register the contract with the Network Guardian Controller.
 *
 * ## Example
 * ```solidity
 *   function initialize(
 *       address feeContract,
 *       address guardianController,
 *       address association,
 *       address developer,
 *       address feeCollector,
 *       string[] memory fnSigs,
 *       uint256[] memory fnFees,
 *       bool storesH1
 *   ) external initializer {
 *       __H1DevelopedApplication_init(
 *           feeContract,
 *           guardianController,
 *           association,
 *           developer,
 *           feeCollector,
 *           fnSigs,
 *           fnFees,
 *           storesH1
 *       );
 *   }
 * ```
 */
abstract contract H1DevelopedApplication is
    NetworkGuardian,
    IH1DevelopedApplication
{
    /* TYPE DECLARATIONS
    ==================================================*/
    using FnSig for bytes;
    using Address for address;

    /* STATE
    ==================================================*/
    /**
     * @dev The Dev Admin role. The account with this role will be able to set
     * fees and update the developer's fee collector address.
     */
    bytes32 public constant DEV_ADMIN_ROLE = keccak256("DEV_ADMIN_ROLE");

    /**
     * @dev Represents the scaling factor used for converting integers to a
     * higher precision.
     */
    uint256 private constant SCALE = 10 ** 18;

    /**
     * @dev Indicates the entered status of the contract is "entered".
     */
    uint256 private constant _H1_DEV_ENTERED = 1;

    /**
     * @dev Indicates the entered status of the contract is "not entered".
     */
    uint256 private constant _H1_DEV_NOT_ENTERED = 2;

    /**
     * @dev The current entered status. Either:
     * -    `_H1_DEV_ENTERED`; or
     * -    `_H1_DEV_NOT_ENTERED`.
     */
    uint256 private _status;

    /**
     * @dev Indicates whether the inheriting contract intends to store H1.
     * Is used as a safety feature to ensure that excess fee payments are not
     * mistakingly refunded to users.
     */
    bool private _storesH1;

    /**
     * @dev The Fee Contract. Will be interacted with for various features,
     * such as retrieving the minimum and maximum fee values, and retrieving the
     * Association's share of the fee.
     */
    IFeeContract private _feeContract;

    /**
     * @dev The address of the developer. This address will be granted the
     * `DEV_ADMIN_ROLE`.
     */
    address private _developer;

    /**
     * @dev The address of the wallet or contract that will collect the
     * developer fees.
     */
    address private _devFeeCollector;

    /**
     * @dev The remaining msg.value after the fee has been paid.
     */
    uint256 private _msgValueAfterFee;

    /**
     * @dev A mapping from a function selector to its associated fee.
     */
    mapping(bytes4 => uint256) private _fnFees;

    /**
     * @dev A mapping from function selectors to its function signature, stored
     * as bytes. `FnSig.toString` can be used to convert the bytes back into a
     * human-readable function signature.
     */
    mapping(bytes4 => bytes) private _fnSigs;

    /* MODIFIERS
    ==================================================*/
    /**
     * @notice This modifier handles the payment of the developer fee. It must
     * be applied to every function that modifies state.
     *
     * @param payableFunction Indicates if the function would have been `payable`
     * if not for the modifier. If true, the `msg.value` will be reduced by the
     * payable fee, and developers will use the `msgValueAfterFee` function to
     * retrieve the adjusted `msg.value`. If false, it is assumed that
     * `msg.value` will not be used and no adjustments will be made.
     *
     * @param refundRemainingBalance Whether the remaining balance after the
     * function execution should be refunded to the sender.
     *
     * @dev Important:
     * Contracts that store H1 should __never__ elect to refund the remaining
     * balance when using the `developerFee` modifier as it will send the
     * contract's balance to the user.
     *
     * Checks if the fee is not only sent via `msg.value`, but also if it
     * is available as balance in the contract to correctly return underfunded
     * multicalls via delegatecall.
     */
    modifier developerFee(bool payableFunction, bool refundRemainingBalance) {
        _before();

        _feeContract.updateFee();
        uint256 fee = getFnFeeAdj(msg.sig);

        if (msg.value < fee || (address(this).balance < fee)) {
            revert H1Developed__InsufficientFunds(address(this).balance, fee);
        }

        if (payableFunction) {
            _msgValueAfterFee = (msg.value - fee);
        }

        if (fee > 0) {
            _payFee(fee);
        }

        _;

        if (!_storesH1 && refundRemainingBalance && address(this).balance > 0) {
            _safeTransfer(msg.sender, address(this).balance);
        }

        delete _msgValueAfterFee;

        _after();
    }

    /* FUNCTIONS
    ==================================================*/

    /* Init
    ========================================*/

    /**
     * @notice Initializes the contract
     *
     * @param feeContract_          The Fee Contract address.
     * @param guardianController_   The Network Guardian Controller address.
     * @param association_          The Haven1 Association address.
     * @param developer_            The address of the contract's developer.
     * @param devFeeCollector_      The address of the developer's fee collector.
     * @param fnSigs_               Function signatures for which fees will be set.
     * @param fnFees_               Fees that will be set for their `fnSigs_` counterparts.
     * @param storesH1_             Indicates whether the contract will store H1.
     */
    function __H1DevelopedApplication_init(
        address feeContract_,
        address guardianController_,
        address association_,
        address developer_,
        address devFeeCollector_,
        string[] memory fnSigs_,
        uint256[] memory fnFees_,
        bool storesH1_
    ) internal onlyInitializing {
        __NetworkGuardian_init(association_, guardianController_);

        __H1DevelopedApplication_init_unchained(
            feeContract_,
            developer_,
            devFeeCollector_,
            fnSigs_,
            fnFees_,
            storesH1_
        );
    }

    /**
     * @param feeContract_      The Fee Contract address.
     * @param developer_        The address of the contract's developer.
     * @param devFeeCollector_  The address of the developer's fee collector.
     * @param fnSigs_           Function signatures for which fees will be set.
     * @param fnFees_           Fees that will be set for their `fnSigs_` counterparts.
     * @param storesH1_             Indicates whether the contract will store H1.
     *
     * @dev Requirements:
     * -    The provided addresses must not be the zero address.
     * -    The supplied fees, if any, must be valid.
     *
     * For more information on the "unchained" method and multiple inheritance
     * see:
     * https://docs.openzeppelin.com/contracts/4.x/upgradeable#multiple-inheritance
     */
    function __H1DevelopedApplication_init_unchained(
        address feeContract_,
        address developer_,
        address devFeeCollector_,
        string[] memory fnSigs_,
        uint256[] memory fnFees_,
        bool storesH1_
    ) internal onlyInitializing {
        feeContract_.assertNotZero();
        developer_.assertNotZero();
        devFeeCollector_.assertNotZero();

        _feeContract = IFeeContract(feeContract_);
        _developer = developer_;
        _devFeeCollector = devFeeCollector_;

        _grantRole(DEV_ADMIN_ROLE, developer_);

        uint256 l = fnSigs_.length;
        uint256 lFees = fnFees_.length;

        if (l != lFees) {
            revert H1Developed__ArrayLengthMismatch(l, lFees);
        }

        if (l > 0) {
            uint256 minFee = _feeContract.getMinDevFee();
            uint256 maxFee = _feeContract.getMaxDevFee();

            for (uint256 i; i < l; i++) {
                string memory sig = fnSigs_[i];
                uint256 fee = fnFees_[i];

                _assertValidFee(fee, minFee, maxFee);
                _setFee(sig, fee);
            }
        }

        _status = _H1_DEV_NOT_ENTERED;
        _storesH1 = storesH1_;
        IFeeContract(feeContract_).setGraceContract(true);
    }

    /* External
    ========================================*/
    /**
     * @inheritdoc IH1DevelopedApplication
     */
    function setFee(
        string memory fnSig,
        uint256 fee
    ) external onlyRole(DEV_ADMIN_ROLE) {
        _assertValidFnSig(fnSig);

        uint256 minFee = _feeContract.getMinDevFee();
        uint256 maxFee = _feeContract.getMaxDevFee();

        _assertValidFee(fee, minFee, maxFee);
        _setFee(fnSig, fee);
    }

    /**
     * @inheritdoc IH1DevelopedApplication
     */
    function setFees(
        string[] memory fnSigs,
        uint256[] memory fees
    ) external onlyRole(DEV_ADMIN_ROLE) {
        uint256 sigLen = fnSigs.length;
        uint256 feesLen = fees.length;

        if (sigLen == 0) {
            revert H1Developed__ArrayLengthZero();
        }

        if (sigLen != feesLen) {
            revert H1Developed__ArrayLengthMismatch(sigLen, feesLen);
        }

        uint256 minFee = _feeContract.getMinDevFee();
        uint256 maxFee = _feeContract.getMaxDevFee();

        for (uint256 i; i < sigLen; i++) {
            string memory sig = fnSigs[i];
            uint256 fee = fees[i];
            _assertValidFnSig(sig);
            _assertValidFee(fee, minFee, maxFee);

            _setFee(sig, fee);
        }
    }

    /**
     * @inheritdoc IH1DevelopedApplication
     */
    function setFeeContract(
        address feeContract_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _feeContract = IFeeContract(feeContract_);
        emit FeeContractAddressUpdated(feeContract_);
    }

    /**
     * @inheritdoc IH1DevelopedApplication
     */
    function setDeveloper(
        address developer_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        developer_.assertNotZero();

        _revokeRole(DEV_ADMIN_ROLE, _developer);
        _grantRole(DEV_ADMIN_ROLE, developer_);

        _developer = developer_;

        emit DeveloperAddressUpdated(developer_);
    }

    /**
     * @inheritdoc IH1DevelopedApplication
     */
    function setDevFeeCollector(
        address devFeeCollector_
    ) external onlyRole(DEV_ADMIN_ROLE) {
        devFeeCollector_.assertNotZero();

        _devFeeCollector = devFeeCollector_;
        emit DevFeeCollectorUpdated(devFeeCollector_);
    }

    /**
     * @inheritdoc IH1DevelopedApplication
     */
    function setStoresH1(bool stores) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _storesH1 = stores;
        emit StoresH1Updated(stores);
    }

    /**
     * @inheritdoc IH1DevelopedApplication
     */
    function feeContract() external view returns (address) {
        return address(_feeContract);
    }

    /**
     * @inheritdoc IH1DevelopedApplication
     */
    function developer() external view returns (address) {
        return _developer;
    }

    /**
     * @inheritdoc IH1DevelopedApplication
     */
    function devFeeCollector() external view returns (address) {
        return _devFeeCollector;
    }

    /**
     * @inheritdoc IH1DevelopedApplication
     */
    function getFnFeeUSD(bytes4 fnSelector) external view returns (uint256) {
        return _fnFees[fnSelector];
    }

    /**
     * @inheritdoc IH1DevelopedApplication
     */
    function storesH1() external view returns (bool) {
        return _storesH1;
    }

    /**
     * @inheritdoc IH1DevelopedApplication
     */
    function getFnSelector(string memory fnSig) external pure returns (bytes4) {
        return bytes4(keccak256(bytes(fnSig)));
    }

    /* Public
    ========================================*/

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
    function getFnFeeAdj(bytes4 fnSel) public view returns (uint256) {
        bool isExempt = _feeContract.isExempt(address(this), fnSel, msg.sender);
        if (isExempt) {
            return 0;
        }

        // If there are no combinations of conditions that result in this call
        // being exempt from fees, then we need to get the appropriate fee and
        // ensure it is valid.
        //
        // The only way for a fee to be zero at this point is if:
        // -    the minimum valid fee is zero; and
        // -    the developer has not set a fee for the function call.
        //
        // In either case, we only need to check that the fee being charged is
        // within the bounds set by the fee contract and adjust it if required.
        //
        // The conditions are:
        // -    If the set fee is less than the minimum fee, the minimum fee is
        //      applied.
        // -    If the set fee is greater than the maximum fee, the maximum fee
        //      is applied.
        uint256 minFee = _feeContract.getMinDevFee();
        uint256 maxFee = _feeContract.getMaxDevFee();
        uint256 fee = _fnFees[fnSel];

        if (fee < minFee) {
            fee = minFee;
        } else if (fee > maxFee) {
            fee = maxFee;
        }

        if (fee == 0) {
            return fee;
        }

        uint256 oneUSDH1 = _feeContract.h1USD();

        return (fee * oneUSDH1) / SCALE;
    }

    /* Internal
    ========================================*/

    /**
     * @notice Returns the current `msg.value` after the developer fee has been
     * subtracted.
     *
     * @return The `msg.value` after the developer fee has been subtracted.
     *
     * @dev To be used in place of `msg.value` in functions that take a developer
     * fee.
     */
    function msgValueAfterFee() internal view returns (uint256) {
        return _msgValueAfterFee;
    }

    /* Private
    ========================================*/

    /**
     * @notice Sets a fee for a given function signature.
     *
     * @param fnSig The function signature.
     * @param fee   The fee.
     *
     * @dev Any validation, such as ensuring the validity of the function
     * signature or the fee must occur _prior_ to calling this function.
     */
    function _setFee(string memory fnSig, uint256 fee) private {
        bytes memory b = bytes(fnSig);
        bytes4 sel = b.toFnSelector();

        _fnFees[sel] = fee;
        _fnSigs[sel] = b;

        emit FeeSet(fnSig, fee);
    }

    /**
     * @notice Pays the `fee`, split between to developer and the Fee Contract.
     *
     * @param fee The total fee to be paid.
     *
     * @dev Emits a `FeePaid` event.
     */
    function _payFee(uint256 fee) private {
        uint256 asscShare = _feeContract.getAssocShare();
        uint256 feeToAssc = (fee * asscShare) / SCALE;
        uint256 feeToDev = fee - feeToAssc;

        _safeTransfer(address(_feeContract), feeToAssc);
        _safeTransfer(_devFeeCollector, feeToDev);

        emit FeePaid(_fnSigs[msg.sig].toString(), feeToAssc, feeToDev);
    }

    /**
     * @notice Transfers an amount of H1 tokens. Will revert if the transfer fails.
     *
     * @param to        The recipient address.
     * @param amount    The amount to send.
     */
    function _safeTransfer(address to, uint256 amount) private {
        (bool success, ) = to.call{ value: amount }(new bytes(0));
        if (!success) {
            revert H1Developed__FeeTransferFailed(to, amount);
        }
    }

    /**
     * @notice Executes logic before allowing the fee payments to be made.
     *
     * @dev Requirements:
     * -    The contract must not already be in an entered state.
     */
    function _before() private {
        if (_status == _H1_DEV_ENTERED) {
            revert H1Developed__ReentrantCall();
        }

        _status = _H1_DEV_ENTERED;
    }

    /**
     * @notice Executes logic after the fee payments have been made.
     */
    function _after() private {
        _status = _H1_DEV_NOT_ENTERED;
    }

    /**
     * @notice Asserts that a given function signature is not of length zero.
     *
     * @param fnSig The function signature.
     */
    function _assertValidFnSig(string memory fnSig) private pure {
        if (bytes(fnSig).length == 0) {
            revert H1Developed__InvalidFnSignature();
        }
    }

    /**
     * @notice Asserts that the fee is within bounds.
     *
     * @param fee The fee to validate.
     * @param min The minimum fee.
     * @param max The maximum fee.
     */
    function _assertValidFee(
        uint256 fee,
        uint256 min,
        uint256 max
    ) private pure {
        if (fee < min || fee > max) {
            revert H1Developed__InvalidFeeAmount(fee);
        }
    }

    /**
     * @dev This empty reserved space allows new state variables to be added
     * without compromising the storage compatibility with existing deployments.
     *
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     *
     * As new variables are added, be sure to reduce the gap as required.
     * For e.g., if the starting `__gap` is `50` and a new variable is added
     * (256 bits in size or part thereof), the gap must now be reduced to `49`.
     */
    uint256[50] private __gap;
}
