// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./lib/Errors.sol";

import { IFeeContract } from "./interfaces/IFeeContract.sol";
import { IFeeOracle } from "./interfaces/IFeeOracle.sol";

import { NetworkGuardian } from "../network-guardian/NetworkGuardian.sol";
import { Address } from "../utils/Address.sol";

/**
 * @title FeeContract
 *
 * @author The Haven1 Development Team
 *
 * @notice This contract defines the core functionality for fee management within
 * the Haven1 ecosystem, including collection, distribution, and fee exemptions.
 */
contract FeeContract is
    ReentrancyGuardUpgradeable,
    NetworkGuardian,
    IFeeContract
{
    /* TYPE DECLARATIONS
    ==================================================*/
    using Address for address;

    /* STATE
    ==================================================*/

    /**
     * @dev Represents the scaling factor used for converting plain integers to
     * a higher precision.
     */
    uint256 private constant _SCALE = 10 ** 18;

    /**
     * @dev The amount of time, in seconds, that must pass between fee distributions.
     */
    uint256 private _distributionEpoch;

    /**
     * @dev The amount of time, in seconds, that must pass between fee updates.
     */
    uint256 private _feeUpdateEpoch;

    /**
     * @dev The grace period, in seconds.
     *
     * This period acts as a buffer to ensure operations that rely on the value
     * of the fee do not fail during periods in which the value is being updated.
     * During the grace period, it is possible for contracts to submit a fee
     * equal either to the new or previous fee - whichever is lower.
     */
    uint256 private _gracePeriod;

    /**
     * @dev The timestamp that the last fee distribution occurred.
     *
     * The timestamp at which the next fee distribution can occur is
     * `_lastDistribution + _distributionEpoch`.
     */
    uint256 private _lastDistribution;

    /**
     * @dev The timestamp at which the next fee update can occur.
     */
    uint256 private _networkFeeResetTimestamp;

    /**
     * @dev The timestamp of the end of the most recent grace period.
     */
    uint256 private _networkFeeGraceTimestamp;

    /**
     * @dev Addresses used for fee distribution.
     *
     * `_channels[i]` corresponds to `_weights[i]`.
     */
    address[] private _channels;

    /**
     * @dev Weights for distribution amounts.
     *
     * `_weights[i]` corresponds to `_channels[i]`.
     */
    uint256[] private _weights;

    /**
     * @dev The total amount that we divide a distribution channel's shares by
     * to compute their payment.
     */
    uint256 private _contractShares;

    /**
     * @dev The share of the developer fee that the Haven1 Association receives.
     *
     * Stored to a precision of 18 decimals.
     */
    uint256 private _assocShare;

    /**
     * @dev The oracle address used to retrieve the H1 price in USD.
     */
    address private _oracle;

    /**
     * @dev The application fee, denominated in amount of H1 tokens.
     */
    uint256 private _fee;

    /**
     * @dev The previous application fee, denominated in amount of H1 tokens.
     * This value is used during the grace period.
     */
    uint256 private _feePrior;

    /**
     * @dev The application fee, denominated in USD.
     *
     * Stored to a precision of 18 decimals.
     */
    uint256 private _feeUSD;

    /**
     * @dev One (1) USD worth of H1 - current period.
     *
     * Stored to a precision of 18 decimals.
     */
    uint256 private _h1USD;

    /**
     * @dev One (1) USD worth of H1 - previous period.
     *
     * Stored to a precision of 18 decimals.
     */
    uint256 private _h1USDPrev;

    /**
     * @dev The minimum fee, in USD, that a developer may charge.
     *
     * Stored to a precision of 18 decimals.
     */
    uint256 private _minDevFee;

    /**
     * @dev The maximum fee, in USD, that a developer may charge.
     *
     * Stored to a precision of 18 decimals.
     */
    uint256 private _maxDevFee;

    /**
     * @dev Mapping of addresses that are considered grace contracts.
     *
     * Grace contracts are able to benefit from the special conditions that
     * occur during the grace period. Addresses that are not marked as a grace
     * contract will always receive the latest fee.
     */
    mapping(address => bool) private _graceContracts;

    /**
     * @dev Mapping of externally owned addresses (EOAs) that are exempt from
     * fee collection.
     */
    mapping(address => bool) private _feeExemptEOAs;

    /**
     * @dev Mapping of callers that are exempt from fee collection when
     * interacting with specific contracts.
     *
     * The key is a `bytes32` hash created from the contract address and the
     * caller address.
     */
    mapping(bytes32 => bool) private _feeExemptCaller;

    /**
     * @dev Mapping of functions that are exempt from fee collection when called
     * on specific contracts.
     *
     * The key is a `bytes32` hash created from the contract address and the
     * function selector.
     */
    mapping(bytes32 => bool) private _feeExemptFunctions;

    /**
     * @dev Mapping of contracts that are exempt from fee collection.
     */
    mapping(address => bool) private _feeExemptContracts;

    /* FUNCTIONS
    ==================================================*/
    /* Constructor
    ========================================*/

    /**
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor() {
        _disableInitializers();
    }

    /* Receive
    ========================================*/

    receive() external payable {
        emit FeesReceived(msg.sender, tx.origin, msg.value);
    }

    /* Init
    ========================================*/
    /**
     * @notice Initializes the contract.
     *
     * @param association_           The Haven1 Association address.
     * @param guardianController_    The Network Guardian Controller address.
     * @param oracle_                The Fee Oracle address.
     * @param channels_              The distribution channels.
     * @param weights_               Each distribution channels' share.
     * @param minDevFee_             The minimum fee, in USD, that a developer may charge.
     * @param maxDevFee_             The maximum fee, in USD, that a developer may charge.
     * @param assocShare_            The share of the developer fee the Association is to receive.
     * @param gracePeriod_           The grace period, in seconds.
     *
     * @dev Requirements:
     * -    None of the supplied address can be the zero address.
     * -    Each distribution channel address must be unique.
     * -    There cannot be more than ten distribution channels.
     * -    Each distribution channel must have a weight supplied and cannot be zero.
     */
    function initialize(
        address association_,
        address guardianController_,
        address oracle_,
        address[] memory channels_,
        uint256[] memory weights_,
        uint256 minDevFee_,
        uint256 maxDevFee_,
        uint256 assocShare_,
        uint256 gracePeriod_
    ) external initializer {
        association_.assertNotZero();
        guardianController_.assertNotZero();
        oracle_.assertNotZero();

        __ReentrancyGuard_init();
        __NetworkGuardian_init(association_, guardianController_);

        uint256 chanLength = channels_.length;
        uint256 weightsLength = weights_.length;

        if (chanLength > 10 || weightsLength > 10) {
            revert FeeContract__ChannelLimitReached();
        }

        if (chanLength != weightsLength) {
            revert FeeContract__ChannelWeightMisalignment();
        }

        if (minDevFee_ > maxDevFee_) {
            revert FeeContract__InvalidFee();
        }

        IFeeOracle(oracle_).refreshOracle();

        _minDevFee = minDevFee_;
        _maxDevFee = maxDevFee_;
        _feeUSD = 1 * _SCALE; // initial fee is one (1) USD worth of H1.
        _assocShare = assocShare_;

        uint256 consult = IFeeOracle(oracle_).consult();
        _fee = (consult * _feeUSD) / _SCALE;
        _h1USD = consult;
        _lastDistribution = block.timestamp;

        _distributionEpoch = 86400;
        _feeUpdateEpoch = 86400;

        _gracePeriod = gracePeriod_;

        _networkFeeResetTimestamp = block.timestamp + _feeUpdateEpoch;
        _oracle = oracle_;

        for (uint8 i; i < chanLength; ++i) {
            address channel = channels_[i];
            uint256 weight = weights_[i];

            _assertValidChannel(channel);
            _assertValidWeight(weight);

            _contractShares += weight;
            _channels.push(channel);
            _weights.push(weight);
        }
    }

    /* External
    ========================================*/

    /**
     * @inheritdoc IFeeContract
     */
    function addChannel(
        address channel_,
        uint256 weight_
    ) external onlyRole(OPERATOR_ROLE) {
        if (_channels.length == 10) {
            revert FeeContract__ChannelLimitReached();
        }

        _assertValidChannel(channel_);
        _assertValidWeight(weight_);

        _channels.push(channel_);
        _weights.push(weight_);

        _contractShares += weight_;

        emit ChannelAdded(channel_, weight_, _contractShares);
    }

    /**
     * @inheritdoc IFeeContract
     */
    function adjustChannel(
        address prevChannel_,
        address newChannel_,
        uint256 weight_
    ) external onlyRole(OPERATOR_ROLE) {
        _assertValidChannel(newChannel_);
        _assertValidWeight(weight_);

        uint8 index = _indexOf(prevChannel_);

        _contractShares -= _weights[index];
        _contractShares += weight_;

        _weights[index] = weight_;
        _channels[index] = newChannel_;

        emit ChannelAdjusted(newChannel_, weight_, _contractShares);
    }

    /**
     * @inheritdoc IFeeContract
     */
    function adjustChannelWeight(
        address channel_,
        uint256 weight_
    ) external onlyRole(OPERATOR_ROLE) {
        _assertValidWeight(weight_);

        uint8 index = _indexOf(channel_);

        _contractShares -= _weights[index];
        _contractShares += weight_;

        _weights[index] = weight_;

        emit ChannelAdjusted(channel_, weight_, _contractShares);
    }

    /**
     * @inheritdoc IFeeContract
     */
    function removeChannel(address channel_) external onlyRole(OPERATOR_ROLE) {
        uint8 index = _indexOf(channel_);

        address removedAddress = _channels[index];

        // Because the order of the channels array does not matter, we can use
        // this more performant method to remove the channel.
        _channels[index] = _channels[_channels.length - 1];
        _channels.pop();

        _contractShares -= _weights[index];

        _weights[index] = _weights[_weights.length - 1];
        _weights.pop();

        emit ChannelRemoved(removedAddress, _contractShares);
    }

    /**
     * @inheritdoc IFeeContract
     */
    function distributeFees() external nonReentrant whenNotGuardianPaused {
        if (block.timestamp <= _lastDistribution + _distributionEpoch) {
            revert FeeContract__EpochLengthNotYetMet();
        }

        _distributeFees();
    }

    /**
     * @inheritdoc IFeeContract
     */
    function forceDistributeFees()
        external
        onlyRole(OPERATOR_ROLE)
        nonReentrant
    {
        _distributeFees();
    }

    /**
     * @inheritdoc IFeeContract
     */
    function updateFee() external {
        if (block.timestamp <= _networkFeeResetTimestamp) return;

        _refreshOracle();

        uint256 oracleVal = queryOracle();
        _feePrior = _fee;
        _fee = (oracleVal * _feeUSD) / _SCALE;

        _h1USDPrev = _h1USD;
        _h1USD = oracleVal;

        _networkFeeResetTimestamp = _feeUpdateEpoch + block.timestamp;
        _networkFeeGraceTimestamp = _gracePeriod + block.timestamp;

        emit FeeUpdated(_fee);
    }

    /**
     * @inheritdoc IFeeContract
     */
    function setMinFee(uint256 fee_) external onlyRole(OPERATOR_ROLE) {
        if (fee_ > _maxDevFee) revert FeeContract__InvalidFee();

        _minDevFee = fee_;
        emit MinFeeUpdated(fee_);
    }

    /**
     * @inheritdoc IFeeContract
     */
    function setMaxFee(uint256 fee_) external onlyRole(OPERATOR_ROLE) {
        if (fee_ < _minDevFee) revert FeeContract__InvalidFee();

        _maxDevFee = fee_;
        emit MaxFeeUpdated(fee_);
    }

    /**
     * @inheritdoc IFeeContract
     */
    function setOracle(address addr_) external onlyRole(OPERATOR_ROLE) {
        addr_.assertNotZero();

        address prev = _oracle;
        _oracle = addr_;

        emit OracleUpdated(prev, addr_);
    }

    /**
     * @inheritdoc IFeeContract
     */
    function setGracePeriod(uint256 period_) external onlyRole(OPERATOR_ROLE) {
        if (period_ > _feeUpdateEpoch) {
            revert FeeContract__InvalidGracePeriod(period_, _feeUpdateEpoch);
        }

        _gracePeriod = period_;
        emit GracePeriodUpdated(period_);
    }

    /**
     * @inheritdoc IFeeContract
     */
    function setGraceContract(bool status_) external {
        _graceContracts[msg.sender] = status_;
    }

    /**
     * @inheritdoc IFeeContract
     */
    function setExemptEOA(
        address eoa_,
        bool skipFee_
    ) external onlyRole(OPERATOR_ROLE) {
        bool isContract = _isContract(eoa_);

        if (isContract) {
            revert FeeContract__OnlyEOA(eoa_);
        }

        _feeExemptEOAs[eoa_] = skipFee_;
        emit ExemptEOAUpdated(eoa_, skipFee_);
    }

    /**
     * @inheritdoc IFeeContract
     */
    function setExemptCaller(
        address contract_,
        address caller_,
        bool skipFee_
    ) external onlyRole(OPERATOR_ROLE) {
        bytes32 h = _contractAndCaller(contract_, caller_);
        _feeExemptCaller[h] = skipFee_;

        emit ExemptCallerUpdated(contract_, caller_, skipFee_);
    }

    /**
     * @inheritdoc IFeeContract
     */
    function setExemptFunction(
        address contract_,
        bytes4 fnSel_,
        bool skipFee_
    ) external onlyRole(OPERATOR_ROLE) {
        bytes32 h = _contractAndFn(contract_, fnSel_);
        _feeExemptFunctions[h] = skipFee_;

        emit ExemptFunctionUpdated(contract_, fnSel_, skipFee_);
    }

    /**
     * @inheritdoc IFeeContract
     */
    function setExemptContract(
        address contract_,
        bool skipFee_
    ) external onlyRole(OPERATOR_ROLE) {
        _feeExemptContracts[contract_] = skipFee_;
        emit ExemptContractUpdated(contract_, skipFee_);
    }

    /**
     * @inheritdoc IFeeContract
     */
    function setFeeUSD(uint256 feeUSD_) external onlyRole(OPERATOR_ROLE) {
        _feeUSD = feeUSD_;
    }

    /**
     * @inheritdoc IFeeContract
     */
    function setAssocShare(
        uint256 assocShare_
    ) external onlyRole(OPERATOR_ROLE) {
        _assocShare = assocShare_;
    }

    /**
     * @inheritdoc IFeeContract
     */
    function setFeeUpdateEpoch(uint256 secs_) external onlyRole(OPERATOR_ROLE) {
        _feeUpdateEpoch = secs_;
        emit FeeEpochUpdated(secs_);
    }

    /**
     * @inheritdoc IFeeContract
     */
    function setDistributionEpoch(
        uint256 secs_
    ) external onlyRole(OPERATOR_ROLE) {
        _distributionEpoch = secs_;
        emit DistributionEpochUpdated(secs_);
    }

    /**
     * @inheritdoc IFeeContract
     */
    function getFeeUSD() external view returns (uint256) {
        return _feeUSD;
    }

    /**
     * @inheritdoc IFeeContract
     */
    function getAssocShare() external view returns (uint256) {
        return _assocShare;
    }

    /**
     * @inheritdoc IFeeContract
     */
    function nextResetTime() external view returns (uint256) {
        return _networkFeeResetTimestamp;
    }

    /**
     * @inheritdoc IFeeContract
     */
    function getDistributionEpoch() external view returns (uint256) {
        return _distributionEpoch;
    }

    /**
     * @inheritdoc IFeeContract
     */
    function getFeeUpdateEpoch() external view returns (uint256) {
        return _feeUpdateEpoch;
    }

    /**
     * @inheritdoc IFeeContract
     */
    function getFeeForContract(
        address contract_,
        address caller_,
        bytes4 fnSel_
    ) external view returns (uint256) {
        if (
            isExemptContract(contract_) ||
            isExemptCaller(contract_, caller_) ||
            isExemptFunction(contract_, fnSel_)
        ) {
            return 0;
        }

        return getFee();
    }

    /**
     * @inheritdoc IFeeContract
     */
    function h1USD() external view returns (uint256) {
        if (_graceContracts[msg.sender] && _isGracePeriod()) {
            return _min(_h1USDPrev, _h1USD);
        }

        return _h1USD;
    }

    /**
     * @inheritdoc IFeeContract
     */
    function getChannels() external view returns (address[] memory) {
        return _channels;
    }

    /**
     * @inheritdoc IFeeContract
     */
    function getWeights() external view returns (uint256[] memory) {
        return _weights;
    }

    /**
     * @inheritdoc IFeeContract
     */
    function getOracleAddress() external view returns (address) {
        return _oracle;
    }

    /**
     * @inheritdoc IFeeContract
     */
    function getChannelWeightByIndex(
        uint8 index
    ) external view returns (address, uint256) {
        return (_channels[index], _weights[index]);
    }

    /**
     * @inheritdoc IFeeContract
     */
    function getTotalContractShares() external view returns (uint256) {
        return _contractShares;
    }

    /**
     * @inheritdoc IFeeContract
     */
    function getLastDistribution() external view returns (uint256) {
        return _lastDistribution;
    }

    /**
     * @inheritdoc IFeeContract
     */
    function getMinDevFee() external view returns (uint256) {
        return _minDevFee;
    }

    /**
     * @inheritdoc IFeeContract
     */
    function getMaxDevFee() external view returns (uint256) {
        return _maxDevFee;
    }

    /**
     * @inheritdoc IFeeContract
     */
    function nextDistributionAmount(
        uint8 index
    ) external view returns (uint256) {
        return (_weights[index] * address(this).balance) / _contractShares;
    }

    /**
     * @inheritdoc IFeeContract
     */
    function getGracePeriod() external view returns (uint256) {
        return _gracePeriod;
    }

    /**
     * @inheritdoc IFeeContract
     */
    function isGraceContract(address addr_) external view returns (bool) {
        return _graceContracts[addr_];
    }

    /**
     * @inheritdoc IFeeContract
     */
    function isExempt(
        address contract_,
        bytes4 fnSel_,
        address caller_
    ) external view returns (bool) {
        return
            isExemptContract(contract_) ||
            isExemptEOA(caller_) ||
            isExemptCaller(contract_, caller_) ||
            isExemptFunction(contract_, fnSel_);
    }

    /* Public
    ========================================*/

    /**
     * @inheritdoc IFeeContract
     */
    function getFee() public view returns (uint256) {
        if (_feeExemptEOAs[tx.origin]) {
            return 0;
        }

        if (_graceContracts[msg.sender] && _isGracePeriod()) {
            return _min(_feePrior, _fee);
        }

        return _fee;
    }

    /**
     * @inheritdoc IFeeContract
     */
    function queryOracle() public view returns (uint256) {
        return IFeeOracle(_oracle).consult();
    }

    /**
     * @inheritdoc IFeeContract
     */
    function isExemptEOA(address addr_) public view returns (bool) {
        return _feeExemptEOAs[addr_];
    }

    /**
     * @inheritdoc IFeeContract
     */
    function isExemptCaller(
        address contract_,
        address caller_
    ) public view returns (bool) {
        bytes32 h = _contractAndCaller(contract_, caller_);
        return _feeExemptCaller[h];
    }

    /**
     * @inheritdoc IFeeContract
     */
    function isExemptFunction(
        address contract_,
        bytes4 fnSel_
    ) public view returns (bool) {
        bytes32 h = _contractAndFn(contract_, fnSel_);
        return _feeExemptFunctions[h];
    }

    /**
     * @inheritdoc IFeeContract
     */
    function isExemptContract(address contract_) public view returns (bool) {
        return _feeExemptContracts[contract_];
    }

    /* Private
    ========================================*/

    /**
     * @notice Distributes fees to the channels.
     *
     * @dev Note that functions calling this function should include a reentrancy
     * guard.
     *
     * Emits `FeesDistributed` events.
     */
    function _distributeFees() private {
        uint256 amount = address(this).balance;

        for (uint8 i; i < _channels.length; ++i) {
            uint256 share = (amount * _weights[i]) / _contractShares;

            (bool sent, ) = _channels[i].call{ value: share }("");

            if (!sent) revert FeeContract__TransferFailed();

            emit FeesDistributed(_channels[i], share);
        }

        _lastDistribution = block.timestamp;
    }

    /**
     * @notice Refreshes the oracle.
     *
     * @return True if the refresh was successful, false otherwise.
     */
    function _refreshOracle() private returns (bool) {
        return IFeeOracle(_oracle).refreshOracle();
    }

    /**
     * @notice Returns the index of an address in the `_channels` array.
     *
     * @param channel_ The address of the channel to search for.
     *
     * @return The index of the address in the `_channels` array.
     *
     * @dev If the address is not found, this function will revert.
     */
    function _indexOf(address channel_) private view returns (uint8) {
        uint256 l = _channels.length;
        for (uint8 i; i < l; ++i) {
            if (_channels[i] == channel_) {
                return i;
            }
        }

        revert FeeContract__ChannelNotFound(channel_);
    }

    /**
     * @notice Returns whether the grace period is active.
     *
     * @return True if the grace period is active, false otherwise.
     */
    function _isGracePeriod() private view returns (bool) {
        return _networkFeeGraceTimestamp > block.timestamp;
    }

    /**
     * @notice Asserts that a given channel address is valid.
     *
     * @param channel_ The channel to be validated.
     *
     * @dev Requirements:
     * -    The channel address must not be the zero address.
     * -    The channel address must not already exist in the `_channels` array.
     */
    function _assertValidChannel(address channel_) private view {
        if (channel_ == address(0)) {
            revert FeeContract__InvalidAddress(channel_);
        }

        uint256 l = _channels.length;

        for (uint8 i; i < l; ++i) {
            if (_channels[i] == channel_) {
                revert FeeContract__InvalidAddress(channel_);
            }
        }
    }

    /**
     * @notice Asserts that a given weight is valid.
     *
     * @param weight_ The weight to be validated.
     *
     * @dev Requirements:
     * -    The weight must not equal zero (0).
     */
    function _assertValidWeight(uint256 weight_) private pure {
        if (weight_ == 0) {
            revert FeeContract__InvalidWeight(weight_);
        }
    }

    /**
     * @notice Returns the minimum between two numbers.
     *
     * @param a The first number to check
     * @param b The second number to check
     *
     * @return The minimum between two numbers.
     */
    function _min(uint256 a, uint256 b) private pure returns (uint256) {
        if (a < b) return a;
        return b;
    }

    /**
     * @notice Returns the Keccak256 hash of a contract address and caller.
     *
     * @param _contract The contract address to hash.
     * @param _caller   The caller address to hash.
     *
     * @return The Keccak256 hash of the supplied contract address and caller.
     */
    function _contractAndCaller(
        address _contract,
        address _caller
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_contract, _caller));
    }

    /**
     * @notice Returns the Keccak256 hash of a contract address and function
     * signature.
     *
     * @param _contract The contract address to hash.
     * @param _fnSig    The function signature to hash.
     *
     * @return The Keccak256 hash of the supplied contract address and function
     * signature.
     */
    function _contractAndFn(
        address _contract,
        bytes4 _fnSig
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_contract, _fnSig));
    }

    /**
     * @notice Returns true if the given address is a contract.
     *
     * @param addr_ The address to check.
     *
     * @return True if the given address is a contract.
     *
     * @dev Note that this function will also return false if the address
     * provided is:
     * -    a contract currently in construction;
     * -    an address at which a contract will later be deployed; or
     * -    an address that was once a contract but has since been destroyed.
     */
    function _isContract(address addr_) private view returns (bool) {
        uint256 size;

        assembly {
            size := extcodesize(addr_)
        }

        return size > 0;
    }
}
