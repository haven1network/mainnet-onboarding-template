// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import { SupportedAttributeType } from "../lib/Attribute.sol";
import { POIType, AccountStatus } from "../lib/POIType.sol";

/**
 * @title IProofOfIdentity
 *
 * @author The Haven1 Development Team
 *
 * @dev The interface for the ProofOfIdentity contract.
 */
interface IProofOfIdentity is IERC721Upgradeable {
    /**
     * @notice Emitted when an attribute is set.
     *
     * @param account   The address for which the attribute was set.
     * @param attribute The ID of the attribute that was set.
     */
    event AttributeSet(address indexed account, uint256 attribute);

    /**
     * @notice Emitted when a new attribute was added to the contract.
     *
     * @param id    The ID of the newly added attribute.
     * @param name  The attribute's name.
     */
    event AttributeAdded(uint256 indexed id, string name);

    /**
     * @notice Emitted when an address is issued a Proof of Identity NFT.
     *
     * @param account The account that received the ID NFT.
     * @param tokenID The token ID that was issued.
     */
    event IdentityIssued(address indexed account, uint256 indexed tokenID);

    /**
     * @notice Emitted when an account's Proof of ID NFT URI is updated.
     *
     * @param account   The account for which the URI was updated.
     * @param tokenID   The ID of the associated token.
     * @param uri       The new URI.
     */
    event TokenURIUpdated(
        address indexed account,
        uint256 indexed tokenID,
        string uri
    );

    /**
     * @notice Emitted when an account's suspension status is updated.
     *
     * @param status    The new suspension status.
     * @param account   The account whose suspended status was updated.
     * @param reason    The reason for the suspension status update.
     */
    event AccountStatusUpdated(
        AccountStatus indexed status,
        address indexed account,
        string reason
    );

    /**
     * @notice Emitted when the number of maximum auxiliary Proof of Identity
     * NFTs allowed per account is updated.
     *
     * @param prev The previous amount.
     * @param curr The new amount.
     */
    event MaxAuxSet(uint256 prev, uint256 curr);

    /**
     * @notice Issues a Proof of Identity NFT to the `account`.
     *
     * @param account       The address of the account to receive the NFT.
     * @param primaryID     Whether the account has verified a primary ID.
     * @param countryCode   The ISO 3166-1 alpha-2 country code of the account.
     * @param liveliness    Whether the account has passed a  proof of liveliness check.
     * @param userType      The account type of the user: 1 = retail. 2 = institution.
     *
     * @dev Requirements:
     * -    The caller must have the role: `OPERATOR_ROLE`.
     * -    The account to receive the NFT must not be the zero address.
     * -    The account to receive the NFT must not already be verified.
     * -    All provided expiries must be valid. See `_assertValidExpiry`.
     *
     * Emits an `AttributeSet` event for each attribute.
     * Emits an `IdentityIssued` event.
     */
    function issueIdentity(
        address account,
        bool primaryID,
        string calldata countryCode,
        bool liveliness,
        uint256 userType,
        uint256[4] memory expiries,
        string calldata uri
    ) external;

    /**
     * @notice Issues an Auxiliary Proof of Identity NFT to the `to` address.
     *
     * @param principal  The address of the Principal account.
     * @param to         The recipient of the Auxiliary ID.
     *
     * @dev Requirements:
     * -    The caller must have the role: `OPERATOR_ROLE`.
     * -    The provided addresses must not be the zero address.
     * -    The Principal account must be valid.
     * -    The Principal account must not have exceeded the maximum allowable
     *      Auxiliary accounts.
     * -    The recipient must not already have a Proof of Identity NFT.
     *
     * Auxiliary IDs mirror the attributes of the Principal and cannot
     * themselves be updated.
     */
    function issueAuxiliary(address principal, address to) external;

    /**
     * @notice Sets an attribute, the value for which is of type `string`.
     *
     * @param account   The address for which the attribute should be set.
     * @param id        The ID of the attribute to set.
     * @param exp       The timestamp of expiry of the attribute.
     * @param data      The attribute data to set as a `string`.
     *
     * @dev Requirements:
     * -    The caller must have the role: `OPERATOR_ROLE`.
     * -    The account must have a Proof of ID NFT.
     * -    The account must be the principal account.
     * -    The attribute ID and expiry must be valid.
     *
     * Emits an `AttributeSet` event.
     */
    function setStringAttribute(
        address account,
        uint256 id,
        uint256 exp,
        string calldata data
    ) external;

    /**
     * @notice Sets an attribute, the value for which is of type `uint256`.
     *
     * @param account   The address for which the attribute should be set.
     * @param id        The ID of the attribute to set.
     * @param exp       The timestamp of expiry of the attribute.
     * @param data      The attribute data to set as `uint256`.
     *
     * @dev Requirements:
     * -    The caller must have the role: `OPERATOR_ROLE`.
     * -    The account must have a Proof of ID NFT.
     * -    The account must be the principal account.
     * -    The attribute ID and expiry must be valid.
     *
     * Emits an `AttributeSet` event.
     */
    function setU256Attribute(
        address account,
        uint256 id,
        uint256 exp,
        uint256 data
    ) external;

    /**
     * @notice Sets an attribute, the value for which is of type `bool`.
     *
     * @param account   The address for which the attribute should be set.
     * @param id        The ID of the attribute to set.
     * @param exp       The timestamp of expiry of the attribute.
     * @param data      The attribute data to set as `bool`.
     *
     * @dev Requirements:
     * -    The caller must have the role: `OPERATOR_ROLE`.
     * -    The account must have a Proof of ID NFT.
     * -    The account must be the principal account.
     * -    The attribute ID and expiry must be valid.
     *
     * Emits an `AttributeSet` event.
     */
    function setBoolAttribute(
        address account,
        uint256 id,
        uint256 exp,
        bool data
    ) external;

    /**
     * @notice Sets an attribute, the value for which is of type `bytes`.
     *
     * @param account   The address for which the attribute should be set.
     * @param id        The ID of the attribute to set.
     * @param exp       The timestamp of expiry of the attribute.
     * @param data      The attribute data to set as `bytes`.
     *
     * @dev Requirements:
     * -    The caller must have the role: `OPERATOR_ROLE`.
     * -    The account must have a Proof of ID NFT.
     * -    The account must be the principal account.
     * -    The attribute ID and expiry must be valid.
     *
     * Emits an `AttributeSet` event.
     */
    function setBytesAttribute(
        address account,
        uint256 id,
        uint256 exp,
        bytes calldata data
    ) external;

    /**
     * @notice Sets the attribute count.
     *
     * @param count The new count.
     *
     * @dev Requirements:
     * -    The caller must have the role: `OPERATOR_ROLE`.
     */
    function setAttributeCount(uint256 count) external;

    /**
     * @notice Adds an attribute to the contract.
     *
     * @param name      The attribute's name.
     * @param attrType  The type of the attribute.
     *
     * @dev Requirements:
     * -    The caller must have the role: `OPERATOR_ROLE`.
     *
     * The current attribute count is used as the next attribute ID, and
     * is then incremented.
     *
     * Emit an `AttributeAdded` event.
     */
    function addAttribute(
        string calldata name,
        SupportedAttributeType attrType
    ) external;

    /**
     * @notice Updates the URI of a token.
     *
     * @param account   The account for which the tokenURI will be updated.
     * @param tokenUri  The URI data to update for the token ID.
     *
     * @dev Requirements:
     * -    The caller must have the role: `OPERATOR_ROLE`.
     * -    The account must have a Proof of ID NFT.
     * -    The account must be the principal account.
     * -    The account must be the owner of the token ID.
     *
     * Emit a `TokenURIUpdated` event.
     */
    function setTokenURI(
        address account,
        uint256 tokenId,
        string calldata tokenUri
    ) external;

    /**
     * @notice Suspends an account and all accounts linked to that address.
     *
     * @param account   The account to suspend.
     * @param reason    The reason for the suspension.
     *
     * @dev Requirements:
     * -    The caller must have the role: `OPERATOR_ROLE`.
     *
     * Emits an `AccountStatusUpdated` event for every account suspended.
     */
    function suspendAccount(address account, string calldata reason) external;

    /**
     * @notice Unsuspends an account and all accounts linked to that address.
     *
     * @param account   The account to unsuspend.
     * @param reason    The reason for the suspension.
     *
     * @dev Requirements:
     * -    The caller must have the role: `OPERATOR_ROLE`.
     *
     * Emits an `AccountStatusUpdated` event for every account unsuspended.
     */
    function unsuspendAccount(address account, string calldata reason) external;

    /**
     * @notice Updates the number of maximum auxiliary Proof of Identity NFTs
     * allowed per account.
     *
     * @param max The new limit.
     *
     * @dev Requirements:
     * -    The caller must have the role: `DEFAULT_ADMIN_ROLE`.
     *
     * Emits a `MaxAuxSet` event.
     */
    function setMaxAux(uint56 max) external;

    /**
     * @notice Returns a tuple containing whether or not a user has validated
     * their primary ID, the expiry of the attribute and the last time it was
     * updated.
     *
     * @param account The address for which the attribute is retrieved.
     *
     * @return Whether the user's primary ID has been validated.
     * @return The expiry of the attribute.
     * @return The last time the attribute was updated.
     */
    function getPrimaryID(
        address account
    ) external view returns (bool, uint256, uint256);

    /**
     * @notice Returns a tuple containing a user's country code (lowercase), the
     * expiry of the attribute and the last time it was updated.
     *
     * @param account The address for which the attribute is retrieved.
     *
     * @return The user's country code.
     * @return The expiry of the attribute.
     * @return The last time the attribute was updated.
     *
     * @dev The country code adheres to the ISO 3166-1 alpha-2 standard.
     */
    function getCountryCode(
        address account
    ) external view returns (string memory, uint256, uint256);

    /**
     * @notice Returns a tuple containing whether a user's proof of liveliness
     * check has been completed, the expiry of the attribute and the last time
     * it was updated.
     *
     * @param account The address for which the attribute is retrieved.
     *
     * @return Whether the user's proof of liveliness check has been completed.
     * @return The expiry of the attribute.
     * @return The last time the attribute was updated.
     */
    function getProofOfLiveliness(
        address account
    ) external view returns (bool, uint256, uint256);

    /**
     * @notice Returns a tuple containing a user's account type, the expiry of
     * the attribute and the last time it was updated.
     *
     * -    1 = Retail
     * -    2 = Institution
     *
     * @param account The address for which the attribute is retrieved.
     *
     * @return The user's account type.
     * @return The expiry of the attribute.
     * @return The last time the attribute was updated.
     */
    function getUserType(
        address account
    ) external view returns (uint256, uint256, uint256);

    /**
     * @notice Returns a tuple containing a user's competency rating, the expiry
     * of the attribute and the last time it was updated.
     *
     * @param account The address for which the attribute is retrieved.
     *
     * @return The user's competency rating.
     * @return The expiry of the attribute.
     * @return The last time the attribute was updated.
     */
    function getCompetencyRating(
        address account
    ) external view returns (uint256, uint256, uint256);

    /**
     * @notice Returns a tuple containing a user's nationality, the expiry
     * of the attribute and the last time it was updated.
     *
     * @param account The address for which the attribute is retrieved.
     *
     * @return The user's nationality.
     * @return The expiry of the attribute.
     * @return The last time the attribute was updated.
     */
    function getNationality(
        address account
    ) external view returns (string memory, uint256, uint256);

    /**
     * @notice Returns a tuple containing a user's ID issuing country, the
     * expiry of the attribute and the last time it was updated.
     *
     * @param account The address for which the attribute is retrieved.
     *
     * @return The user's ID issuing country.
     * @return The expiry of the attribute.
     * @return The last time the attribute was updated.
     */
    function getIDIssuingCountry(
        address account
    ) external view returns (string memory, uint256, uint256);

    /**
     * @notice Returns a tuple containing the string attribute, the expiry of
     * the attribute and the last time it was updated.
     *
     * @param id        The attribute ID to fetch.
     * @param account   The address for which the attribute is retrieved.
     *
     * @return The string attribute.
     * @return The expiry of the attribute.
     * @return The last time the attribute was updated.
     *
     * @dev Requirements:
     * -    A valid attribute ID.
     *
     * If the attribute has not yet been set for the supplied address, the
     * default `("", 0, 0)` case will be returned.
     */
    function getStringAttribute(
        uint256 id,
        address account
    ) external view returns (string memory, uint256, uint256);

    /**
     * @notice Returns a tuple containing the uint256 attribute, the expiry of
     * the attribute and the last time it was updated.
     *
     * @param id        The attribute ID to fetch.
     * @param account   The address for which the attribute is retrieved.
     *
     * @return The U256 attribute.
     * @return The expiry of the attribute.
     * @return The last time the attribute was updated.
     *
     * @dev Requirements:
     * -    A valid attribute ID.
     *
     * If the attribute has not yet been set for the supplied address, the
     * default `(0, 0, 0)` case will be returned.
     */
    function getU256Attribute(
        uint256 id,
        address account
    ) external view returns (uint256, uint256, uint256);

    /**
     * @notice Returns a tuple containing the bool attribute, the expiry of
     * the attribute and the last time it was updated.
     *
     * @param id        The attribute ID to fetch.
     * @param account   The address for which the attribute is retrieved.
     *
     * @return The bool attribute.
     * @return The expiry of the attribute.
     * @return The last time the attribute was updated.
     *
     * @dev Requirements:
     * -    A valid attribute ID.
     *
     * If the attribute has not yet been set for the supplied address, the
     * default `(false, 0, 0)` case will be returned.
     */
    function getBoolAttribute(
        uint256 id,
        address account
    ) external view returns (bool, uint256, uint256);

    /**
     * @notice Returns a tuple containing the bytes attribute, the expiry of
     * the attribute and the last time it was updated.
     *
     * @param id        The attribute ID to fetch.
     * @param account   The address for which the attribute is retrieved.
     *
     * @return The bytes attribute.
     * @return The expiry of the attribute.
     * @return The last time the attribute was updated.
     *
     * If the attribute has not yet been set for the supplied address, the
     * default `("0x", 0, 0)` case will be returned.
     */
    function getBytesAttribute(
        uint256 id,
        address account
    ) external view returns (bytes memory, uint256, uint256);

    /**
     * @notice Retrieve the name of a given attribute.
     *
     * @param id The ID of the attribute for which the name is fetched.
     *
     * @return The name of the attribute.
     *
     * @dev Will return an empty string (`""`) if the attribute ID provided is
     * invalid.
     */
    function getAttributeName(uint256 id) external view returns (string memory);

    /**
     * @notice Returns if a given account is suspended.
     *
     * @param account The account the check.
     *
     * @return True if suspended, false otherwise.
     */
    function isSuspended(address account) external view returns (bool);

    /**
     * @notice Returns an account's token ID.
     *
     * @param account The address for which the token ID is retrieved.
     *
     * @return The token ID.
     */
    function tokenID(address account) external view returns (uint256);

    /**
     * @notice Returns the current token ID counter value.
     *
     * @return The token ID counter value.
     */
    function tokenIDCounter() external view returns (uint256);

    /**
     * @notice Returns amount of attributes currently tracked by the contract.
     *
     * @return The amount of attributes currently tracked by the contract.
     *
     * @dev Note that the attribute IDs are zero-indexed, so the max valid ID
     * is `attributeCount - 1`.
     */
    function attributeCount() external view returns (uint256);

    /**
     * @notice Returns the `POIType` associated with a given account.
     *
     * @param account The address for which the POI Type is retrieved.
     *
     * @return The POI Type.
     */
    function poiType(address account) external view returns (POIType);

    /**
     * @notice Returns a given account's Principal account.
     *
     * @param account The address for which the Principal is retrieved.
     *
     * @return The Principal account.
     */
    function principalAccount(address account) external view returns (address);

    /**
     * @notice Returns all Auxiliary accounts associated with a given account.
     *
     * @param account The address for which the Auxiliary accounts are retrieved.
     *
     * @return The Auxiliary accounts.
     */
    function auxiliaryAccounts(
        address account
    ) external view returns (address[] memory);

    /**
     * @notice Returns the maximum number of auxiliary Proof of Identity NFTs
     * that can be issued to a specific address during its lifetime.
     *
     * @return The maximum number of auxiliary Proof of Identity NFTs that can
     * be issued per account.
     */
    function maxAuxiliaryAccounts() external view returns (uint256);

    /**
     * @notice Returns the Permissions Interface address.
     * @return The Permissions Interface  address.
     */
    function getPermissionsInterface() external view returns (address);

    /**
     * @notice Returns the Account Manager address.
     * @return The Account Manager address.
     */
    function getAccountManager() external view returns (address);

    /**
     * @notice Sets the name of an ID.
     *
     * @param id    The ID of the attribute for which the name is to be set.
     * @param name  The name to set.
     *
     * @dev Requirements:
     * -    The caller must have the role: `OPERATOR_ROLE`.
     * -    The attribute ID must be within the range of possible valid IDs.
     */
    function setAttributeName(uint256 id, string calldata name) external;

    /**
     * @notice Sets the type of the attribute.
     *
     * @param id        The ID of the attribute for which the type is to be set.
     * @param attrType  The type of the attribute
     *
     * @dev Requirements:
     * -    The caller must have the role: `OPERATOR_ROLE`.
     */
    function setAttributeType(
        uint256 id,
        SupportedAttributeType attrType
    ) external;

    /**
     * @notice Increments the attribute count.
     *
     * @dev Requirements:
     * -    The caller must have the role: `OPERATOR_ROLE`.
     */
    function incrementAttributeCount() external;

    /**
     * @notice Returns an attribute's type.
     * E.g., 0 (primaryID) => "bool"
     * E.g., 1 (countryCode) => "string"
     *
     * @param id The ID of the attribute for which the type is retrieved.
     *
     * @return The type of the attribute.
     *
     * @dev Requirements:
     * -    The attribute ID must be within the range of possible valid IDs.
     */
    function getAttributeType(uint256 id) external view returns (string memory);

    /**
     * @notice Returns the URI for a given token ID.
     *
     * @param tokenId The token ID for which a URI should be retrieved.
     *
     * @return The token URI.
     *
     * @dev Requirements:
     * -    The account must have a Proof of ID NFT.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
