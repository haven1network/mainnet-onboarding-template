// SPDX-License-Identifier: MIAccountSuspendedT
pragma solidity ^0.8.0;

import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { IERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

import "./lib/Errors.sol";
import { NetworkGuardian } from "../network-guardian/NetworkGuardian.sol";
import { Address } from "../utils/Address.sol";
import { BytesConversion } from "./lib/BytesConversion.sol";
import { Attribute, SupportedAttributeType, AttributeUtils } from "./lib/Attribute.sol";
import { POIType, POITypeUtils, AccountStatus } from "./lib/POIType.sol";
import { IProofOfIdentity } from "./interfaces/IProofOfIdentity.sol";
import { IPermissionsInterface } from "./interfaces/vendor/IPermissionsInterface.sol";
import { IAccountManager } from "./interfaces/vendor/IAccountManager.sol";

/**
 * @title Proof Of Identity
 *
 * @author The Haven1 Development Team
 *
 * @dev Currently tracked attributes, their ID and types:
 *
 * |----|-------------------|---------|----------------|
 * | ID |     Attribute     |  Type   | Example Return |
 * |----|-------------------|---------|----------------|
 * |  0 | primaryID         | bool    | true           |
 * |  1 | countryCode       | string  | "sg"           |
 * |  2 | proofOfLiveliness | bool    | true           |
 * |  3 | userType          | uint256 | 1              |
 * |  4 | competencyRating  | uint256 | 88             |
 * |  5 | nationality       | string  | "sg"           |
 * |  6 | idIssuingCountry  | string  | "sg"           |
 * |----|-------------------|---------|----------------|
 *
 * Each attribute will also have a corresponding `expiry` and an `updatedAt`
 * field.
 *
 * The following fields are guaranteed to have a non-zero entry for users who
 * successfully completed their identity check:
 *  - primaryID;
 *  - countryCode;
 *  - proofOfLiveliness;  and
 *  - userType.
 *
 * There are explicit getters for all seven (7) of the currently supported
 * attributes.
 *
 * Note that while this contract is upgradable, provisions have been made to
 * allow attributes to be added without the need for upgrading. An event will be
 * emitted (`AttributeAdded`) if an attribute is added. If an attribute is added
 * but the contract has not been upgraded to provide a new explicit getter,
 * you can use the four (4) generic getters to retrieve the information.
 *
 * There is a need for programmatic issuance and maintenance of Proof of
 * Identity NFTs. Accessing these features of the contracts is therefore
 * delegated to accounts with the role `OPERATOR_ROLE` (declared in the
 * Network Guardian contract).
 *
 * A Proof of Identity NFT can either be of type `Principal` or `Auxiliary`.
 * The initial Proof of Identity NFT issued to a user is of type `Principal`.
 * All subsequent IDs issued to that user are of type `Auxiliary`. Auxiliary
 * IDs mirror the attributes of the Principal and cannot themselves be updated.
 * This system allows a verified user to have multiple wallets active on Haven1
 * (up to the maximum allowable amount).
 *
 * Note the decision to not allow issued Auxiliary accounts to be burned; they
 * may only be suspended. The maximum amount of Auxiliary accounts can be
 * updated at any time. This means that if the cap is lowered, accounts that have
 * already minted above the new cap will not retrospectively be affected.
 *
 * If a user's account is suspended or unsuspended, so too are __all__ linked
 * accounts.
 */
contract ProofOfIdentity is
    ERC721Upgradeable,
    NetworkGuardian,
    IProofOfIdentity
{
    /* TYPE DECLARATIONS
    ==================================================*/
    using BytesConversion for bytes;
    using AttributeUtils for Attribute;
    using AttributeUtils for SupportedAttributeType;
    using POITypeUtils for POIType;
    using Address for address;

    /* STATE
    ==================================================*/

    /**
     * @dev The Quorum org.
     */
    string private constant ORG = "HAVEN1";

    /**
     * @dev Maps an address to an "attribute id" to an `Attribute`.
     */
    mapping(address => mapping(uint256 => Attribute)) private _attributes;

    /**
     * @dev Maps the ID of an attribute to its name.
     */
    mapping(uint256 => string) private _attributeToName;

    /**
     * @dev Maps the ID of an attribute to its expected type.
     * E.g., 0 (primaryID) => `SupportedAttributeType.BOOL`
     */
    mapping(uint256 => SupportedAttributeType) private _attributeToType;

    /**
     * @dev Mapping owner addresses to their token ID.
     * The compliment of {ERC721Upgradeable-_owners}
     */
    mapping(address => uint256) private _addressToTokenID;

    /**
     * @dev Maps an address to its Proof of Identity type.
     * Zero value here is `POIType.NOT_ISSUED`.
     */
    mapping(address => POIType) private _addressToPOIType;

    /**
     * @dev Holds a given address' principal account.
     */
    mapping(address => address) private _principal;

    /**
     * @dev Holds a given principal's auxiliary accounts.
     * The compliment of `_principal`.
     */
    mapping(address => address[]) private _principalToAux;

    /**
     * @dev Maps a tokenID to a custom URI.
     */
    mapping(uint256 => string) private _tokenURI;

    /**
     * @dev Tracks the token IDs.
     */
    uint256 private _tokenIDCounter;

    /**
     * @dev Holds the total amount of attributes tracked in this version of the
     * contract. As the attribute IDs are zero-indexed, this number also
     * represents the ID to be used for the __next__ attribute.
     */
    uint256 private _attributeCount;

    /**
     * @dev Defines the maximum number of auxiliary Proof of Identity NFTs
     * that can be issued to a specific address during its lifetime.
     *
     * As this contract manages suspending and unsuspending accounts across
     * different Proof of Identity types bidirectionally, the maximum number of
     * auxiliary NFTs allowed is limited by the number of iterations possible in
     * a single transaction rover the relevant `_principalToAux` array.
     */
    uint256 private _maxAux;

    /**
     * @dev Stores the Quorum Network permissions interface address.
     */
    IPermissionsInterface private _permissionsInterface;

    /**
     * @dev Stores the Quorum Network permissions interface address.
     */
    IAccountManager private _accountManager;

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

    /* Init
    ========================================*/

    /**
     * @notice Initializes the contract.
     *
     * @param association           The Haven1 Association address.
     * @param permissionsInterface  The Permissions Interface address.
     * @param accountManager        The Account Manager address.
     * @param guardianController    The Network Guardian Controller address.
     *
     * @dev Requirements:
     * -    The association address must not be the zero address.
     */
    function initialize(
        address association,
        address permissionsInterface,
        address accountManager,
        address guardianController
    ) external initializer {
        association.assertNotZero();
        permissionsInterface.assertNotZero();
        accountManager.assertNotZero();
        guardianController.assertNotZero();

        __NetworkGuardian_init(association, guardianController);
        __ERC721_init("Proof of Identity", "H1-ID");

        _permissionsInterface = IPermissionsInterface(permissionsInterface);
        _accountManager = IAccountManager(accountManager);
    }

    /* External
    ========================================*/

    /**
     * @inheritdoc IProofOfIdentity
     */
    function issueIdentity(
        address account,
        bool primaryID,
        string calldata countryCode,
        bool liveliness,
        uint256 userType,
        uint256[4] memory expiries,
        string calldata uri
    ) external onlyRole(OPERATOR_ROLE) whenNotGuardianPaused {
        account.assertNotZero();
        _assertIsNotVerified(account);

        // all expiries must be valid
        for (uint8 i; i < 4; i++) {
            uint256 exp = expiries[i];
            _assertValidExpiry(exp);
        }

        _tokenIDCounter++;

        uint256 id = _tokenIDCounter;

        _tokenURI[id] = uri;
        _addressToTokenID[account] = id;
        _addressToPOIType[account] = POIType.PRINCIPAL;
        _principal[account] = account;

        _setAttr(account, 0, expiries[0], abi.encode(primaryID));
        _setAttr(account, 1, expiries[1], abi.encode(countryCode));
        _setAttr(account, 2, expiries[2], abi.encode(liveliness));
        _setAttr(account, 3, expiries[3], abi.encode(userType));

        _mint(account, id);
        _permissionsInterface.assignAccountRole(account, ORG, "VTCALL");

        emit IdentityIssued(account, id);
    }

    /**
     * @inheritdoc IProofOfIdentity
     */
    function issueAuxiliary(
        address principal,
        address to
    ) external onlyRole(OPERATOR_ROLE) whenNotGuardianPaused {
        principal.assertNotZero();
        to.assertNotZero();

        _addressToPOIType[principal].assertIsPrincipal();
        _assertIsNotSuspended(principal);
        _assertIsNotVerified(to);

        if (_principalToAux[principal].length >= _maxAux) {
            revert ProofOfIdentity__MaxAuxiliaryReached();
        }

        _tokenIDCounter++;

        uint256 auxID = _tokenIDCounter;

        _addressToTokenID[to] = auxID;
        _addressToPOIType[to] = POIType.AUXILIARY;

        _principal[to] = principal;
        _principalToAux[principal].push(to);

        _mint(to, auxID);
        _permissionsInterface.assignAccountRole(to, ORG, "VTCALL");

        emit IdentityIssued(to, auxID);
    }

    /**
     * @inheritdoc IProofOfIdentity
     */
    function setStringAttribute(
        address account,
        uint256 id,
        uint256 exp,
        string calldata data
    ) external onlyRole(OPERATOR_ROLE) whenNotGuardianPaused {
        _assertIsVerified(account);

        _addressToPOIType[account].assertIsPrincipal();
        _assertValidAttributeID(id, SupportedAttributeType.STRING);
        _assertValidExpiry(exp);

        _setAttr(account, id, exp, abi.encode(data));
    }

    /**
     * @inheritdoc IProofOfIdentity
     */
    function setU256Attribute(
        address account,
        uint256 id,
        uint256 exp,
        uint256 data
    ) external onlyRole(OPERATOR_ROLE) whenNotGuardianPaused {
        _assertIsVerified(account);

        _addressToPOIType[account].assertIsPrincipal();
        _assertValidAttributeID(id, SupportedAttributeType.U256);
        _assertValidExpiry(exp);

        _setAttr(account, id, exp, abi.encode(data));
    }

    /**
     * @inheritdoc IProofOfIdentity
     */
    function setBoolAttribute(
        address account,
        uint256 id,
        uint256 exp,
        bool data
    ) external onlyRole(OPERATOR_ROLE) whenNotGuardianPaused {
        _assertIsVerified(account);

        _addressToPOIType[account].assertIsPrincipal();
        _assertValidAttributeID(id, SupportedAttributeType.BOOL);
        _assertValidExpiry(exp);

        _setAttr(account, id, exp, abi.encode(data));
    }

    /**
     * @inheritdoc IProofOfIdentity
     */
    function setBytesAttribute(
        address account,
        uint256 id,
        uint256 exp,
        bytes calldata data
    ) external onlyRole(OPERATOR_ROLE) whenNotGuardianPaused {
        _assertIsVerified(account);

        _addressToPOIType[account].assertIsPrincipal();
        _assertValidAttributeID(id, SupportedAttributeType.BYTES);
        _assertValidExpiry(exp);

        _setAttr(account, id, exp, abi.encode(data));
    }

    /**
     * @inheritdoc IProofOfIdentity
     */
    function setAttributeCount(
        uint256 count
    ) external onlyRole(OPERATOR_ROLE) whenNotGuardianPaused {
        _attributeCount = count;
    }

    /**
     * @inheritdoc IProofOfIdentity
     */
    function addAttribute(
        string calldata name,
        SupportedAttributeType attrType
    ) external onlyRole(OPERATOR_ROLE) whenNotGuardianPaused {
        uint256 id = _attributeCount;

        incrementAttributeCount();

        setAttributeName(id, name);
        setAttributeType(id, attrType);

        emit AttributeAdded(id, name);
    }

    /**
     * @inheritdoc IProofOfIdentity
     */
    function setTokenURI(
        address account,
        uint256 tokenId,
        string calldata tokenUri
    ) external onlyRole(OPERATOR_ROLE) whenNotGuardianPaused {
        if (!_exists(tokenId)) {
            revert ProofOfIdentity__InvalidTokenID(tokenId);
        }

        _addressToPOIType[account].assertIsPrincipal();

        address owner = _ownerOf(tokenId);
        if (account != owner) {
            revert ProofOfIdentity__IsNotOwner(owner, account);
        }

        _tokenURI[tokenId] = tokenUri;

        emit TokenURIUpdated(account, tokenId, tokenUri);
    }

    /**
     * @inheritdoc IProofOfIdentity
     */
    function suspendAccount(
        address account,
        string calldata reason
    ) external onlyRole(OPERATOR_ROLE) whenNotGuardianPaused {
        address p = _principal[account];
        address[] memory aux = _principalToAux[p];

        _permissionsInterface.updateAccountStatus(ORG, p, 1);

        uint256 l = aux.length;
        for (uint256 i; i < l; i++) {
            address a = aux[i];
            _permissionsInterface.updateAccountStatus(ORG, a, 1);
            emit AccountStatusUpdated(AccountStatus.SUSPENDED, a, reason);
        }

        emit AccountStatusUpdated(AccountStatus.SUSPENDED, p, reason);
    }

    /**
     * @inheritdoc IProofOfIdentity
     */
    function unsuspendAccount(
        address account,
        string calldata reason
    ) external onlyRole(OPERATOR_ROLE) whenNotGuardianPaused {
        address p = _principal[account];
        address[] memory aux = _principalToAux[p];

        _permissionsInterface.updateAccountStatus(ORG, p, 2);

        uint256 l = aux.length;

        for (uint256 i; i < l; i++) {
            address a = aux[i];
            _permissionsInterface.updateAccountStatus(ORG, a, 2);
            emit AccountStatusUpdated(AccountStatus.UNSUSPENDED, a, reason);
        }

        emit AccountStatusUpdated(AccountStatus.UNSUSPENDED, p, reason);
    }

    /**
     * @inheritdoc IProofOfIdentity
     */
    function setMaxAux(
        uint56 max
    ) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotGuardianPaused {
        uint256 prev = _maxAux;
        _maxAux = max;
        emit MaxAuxSet(prev, _maxAux);
    }

    /**
     * @inheritdoc IProofOfIdentity
     */
    function getPrimaryID(
        address account
    ) external view returns (bool, uint256, uint256) {
        address p = _principal[account];
        Attribute memory attr = _attributes[p][0];
        return (attr.data.toBool(), attr.expiry, attr.updatedAt);
    }

    /**
     * @inheritdoc IProofOfIdentity
     */
    function getCountryCode(
        address account
    ) external view returns (string memory, uint256, uint256) {
        address p = _principal[account];
        Attribute memory attr = _attributes[p][1];
        return (attr.data.toString(), attr.expiry, attr.updatedAt);
    }

    /**
     * @inheritdoc IProofOfIdentity
     */
    function getProofOfLiveliness(
        address account
    ) external view returns (bool, uint256, uint256) {
        address p = _principal[account];
        Attribute memory attr = _attributes[p][2];
        return (attr.data.toBool(), attr.expiry, attr.updatedAt);
    }

    /**
     * @inheritdoc IProofOfIdentity
     */
    function getUserType(
        address account
    ) external view returns (uint256, uint256, uint256) {
        address p = _principal[account];
        Attribute memory attr = _attributes[p][3];
        return (attr.data.toU256(), attr.expiry, attr.updatedAt);
    }

    /**
     * @inheritdoc IProofOfIdentity
     */
    function getCompetencyRating(
        address account
    ) external view returns (uint256, uint256, uint256) {
        address p = _principal[account];
        Attribute memory attr = _attributes[p][4];
        return (attr.data.toU256(), attr.expiry, attr.updatedAt);
    }

    /**
     * @inheritdoc IProofOfIdentity
     */
    function getNationality(
        address account
    ) external view returns (string memory, uint256, uint256) {
        address p = _principal[account];
        Attribute memory attr = _attributes[p][5];
        return (attr.data.toString(), attr.expiry, attr.updatedAt);
    }

    /**
     * @inheritdoc IProofOfIdentity
     */
    function getIDIssuingCountry(
        address account
    ) external view returns (string memory, uint256, uint256) {
        address p = _principal[account];
        Attribute memory attr = _attributes[p][6];
        return (attr.data.toString(), attr.expiry, attr.updatedAt);
    }

    /**
     * @inheritdoc IProofOfIdentity
     */
    function getStringAttribute(
        uint256 id,
        address account
    ) external view returns (string memory, uint256, uint256) {
        _assertValidAttributeID(id, SupportedAttributeType.STRING);

        address p = _principal[account];
        Attribute memory attr = _attributes[p][id];
        return (attr.data.toString(), attr.expiry, attr.updatedAt);
    }

    /**
     * @inheritdoc IProofOfIdentity
     */
    function getU256Attribute(
        uint256 id,
        address account
    ) external view returns (uint256, uint256, uint256) {
        _assertValidAttributeID(id, SupportedAttributeType.U256);

        address p = _principal[account];
        Attribute memory attr = _attributes[p][id];
        return (attr.data.toU256(), attr.expiry, attr.updatedAt);
    }

    /**
     * @inheritdoc IProofOfIdentity
     */
    function getBoolAttribute(
        uint256 id,
        address account
    ) external view returns (bool, uint256, uint256) {
        _assertValidAttributeID(id, SupportedAttributeType.BOOL);

        address p = _principal[account];
        Attribute memory attr = _attributes[p][id];
        return (attr.data.toBool(), attr.expiry, attr.updatedAt);
    }

    /**
     * @inheritdoc IProofOfIdentity
     */
    function getBytesAttribute(
        uint256 id,
        address account
    ) external view returns (bytes memory, uint256, uint256) {
        _assertValidAttributeID(id, SupportedAttributeType.BYTES);

        address p = _principal[account];
        Attribute memory attr = _attributes[p][id];
        return (attr.data.toBytes(), attr.expiry, attr.updatedAt);
    }

    /**
     * @inheritdoc IProofOfIdentity
     */
    function getAttributeName(
        uint256 id
    ) external view returns (string memory) {
        return _attributeToName[id];
    }

    /**
     * @inheritdoc IProofOfIdentity
     */
    function getAttributeType(
        uint256 id
    ) external view returns (string memory) {
        if (id >= _attributeCount) {
            revert ProofOfIdentity__InvalidAttribute(id);
        }

        return _attributeToType[id].toString();
    }

    /**
     * @inheritdoc IProofOfIdentity
     */
    function isSuspended(address account) external view returns (bool) {
        return _accountManager.getAccountStatus(account) != 2;
    }

    /**
     * @inheritdoc IProofOfIdentity
     */
    function tokenID(address account) external view returns (uint256) {
        return _addressToTokenID[account];
    }

    /**
     * @inheritdoc IProofOfIdentity
     */
    function tokenIDCounter() external view returns (uint256) {
        return _tokenIDCounter;
    }

    /**
     * @inheritdoc IProofOfIdentity
     */
    function attributeCount() external view returns (uint256) {
        return _attributeCount;
    }

    /**
     * @inheritdoc IProofOfIdentity
     */
    function poiType(address account) external view returns (POIType) {
        return _addressToPOIType[account];
    }

    /**
     * @inheritdoc IProofOfIdentity
     */
    function principalAccount(address account) external view returns (address) {
        return _principal[account];
    }

    /**
     * @inheritdoc IProofOfIdentity
     */
    function auxiliaryAccounts(
        address account
    ) external view returns (address[] memory) {
        address p = _principal[account];
        return _principalToAux[p];
    }

    /**
     * @inheritdoc IProofOfIdentity
     */
    function maxAuxiliaryAccounts() external view returns (uint256) {
        return _maxAux;
    }

    /**
     * @inheritdoc IProofOfIdentity
     */
    function getPermissionsInterface() external view returns (address) {
        return address(_permissionsInterface);
    }

    /**
     * @inheritdoc IProofOfIdentity
     */
    function getAccountManager() external view returns (address) {
        return address(_accountManager);
    }

    /* Public
    ========================================*/

    /**
     * @inheritdoc IProofOfIdentity
     */
    function setAttributeName(
        uint256 id,
        string calldata name
    ) public onlyRole(OPERATOR_ROLE) whenNotGuardianPaused {
        if (id >= _attributeCount) {
            revert ProofOfIdentity__InvalidAttribute(id);
        }

        _attributeToName[id] = name;
    }

    /**
     * @inheritdoc IProofOfIdentity
     */
    function setAttributeType(
        uint256 id,
        SupportedAttributeType attrType
    ) public onlyRole(OPERATOR_ROLE) whenNotGuardianPaused {
        _attributeToType[id] = attrType;
    }

    /**
     * @inheritdoc IProofOfIdentity
     */
    function incrementAttributeCount()
        public
        onlyRole(OPERATOR_ROLE)
        whenNotGuardianPaused
    {
        _attributeCount++;
    }

    /**
     * @inheritdoc IProofOfIdentity
     */
    function tokenURI(
        uint256 tokenId
    )
        public
        view
        virtual
        override(ERC721Upgradeable, IProofOfIdentity)
        returns (string memory)
    {
        if (!_exists(tokenId)) {
            revert ProofOfIdentity__InvalidTokenID(tokenId);
        }

        address owner = _ownerOf(tokenId);
        address p = _principal[owner];
        uint256 id = _addressToTokenID[p];

        return _tokenURI[id];
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721Upgradeable, IERC165Upgradeable, NetworkGuardian)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /* Internal
    ========================================*/
    /**
     * @notice Sets an attribute.
     *
     * @param account   The address for which the attribute should be set.
     * @param id        The ID of the attribute to set.
     * @param exp       The timestamp of expiry of the attribute.
     * @param data      The attribute data to set in bytes.
     *
     * @dev Emits an `AttributeSet` event.
     */
    function _setAttr(
        address account,
        uint256 id,
        uint256 exp,
        bytes memory data
    ) internal {
        Attribute storage attr = _attributes[account][id];

        attr.setAttribute(exp, block.timestamp, data);

        emit AttributeSet(account, id);
    }

    /**
     * @dev Overrides OpenZeppelin's {ERC721Upgradeable} `_beforeTokenTransfer`
     * implementation to prevent transferring Proof of Identity NFTs.
     */
    function _beforeTokenTransfer(
        address from,
        address,
        uint256,
        uint256
    ) internal virtual override {
        if (from != address(0)) {
            revert ProofOfIdentity__IDNotTransferable();
        }
    }

    /* Private
    ========================================*/

    /**
     * @notice Validates a given attribute ID.
     *
     * @param id            The ID to validate.
     * @param expectedType  The expected type of the ID.
     *
     * @dev Requirements:
     * -    ID must be within the range of possible valid IDs.
     * -    Type of ID must match the expected type.
     */
    function _assertValidAttributeID(
        uint256 id,
        SupportedAttributeType expectedType
    ) private view {
        if (id >= _attributeCount || _attributeToType[id] != expectedType) {
            revert ProofOfIdentity__InvalidAttribute(id);
        }
    }

    /**
     * @notice Validates a given expiry.
     *
     * @param expiry The expiry to validate.
     *
     * @dev Requirements:
     * -    Expiry must be greater than the current timestamp.
     */
    function _assertValidExpiry(uint256 expiry) private view {
        if (expiry <= block.timestamp) {
            revert ProofOfIdentity__InvalidExpiry(expiry);
        }
    }

    /**
     * @notice Asserts that a given address is verified.
     *
     * @param addr The address to check.
     *
     * @dev Requirements:
     * -    Balance of the address must not be zero.
     */
    function _assertIsVerified(address addr) private view {
        if (balanceOf(addr) == 0) {
            revert ProofOfIdentity__IsNotVerified(addr);
        }
    }

    /**
     * @notice Asserts that a given address is not suspended.
     *
     * @param addr The address to check.
     *
     * @dev Requirements:
     * -    Balance of the address must have an account status of `2`.
     */
    function _assertIsNotSuspended(address addr) private view {
        if (_accountManager.getAccountStatus(addr) != 2) {
            revert ProofOfIdentity__IsSuspended(addr);
        }
    }

    /**
     * @notice Asserts that a given address is not verified.
     *
     * @param addr The address to check.
     *
     * @dev Requirements:
     * -    Balance of the address must be zero.
     */
    function _assertIsNotVerified(address addr) private view {
        if (balanceOf(addr) != 0) {
            revert ProofOfIdentity__IsVerified(addr);
        }
    }
}
