// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice Raised when an invalid attribute ID has been supplied.
 * @param attribute The invalid attribute ID.
 */
error ProofOfIdentity__InvalidAttribute(uint256 attribute);

/**
 * @notice Raised when an invalid expiry has been supplied.
 * @param expiry The invalid expiry.
 */
error ProofOfIdentity__InvalidExpiry(uint256 expiry);

/**
 * @notice Raised when an attempt to access a feature that requires an account
 * to be verified.
 *
 * @param account The address of the unverified account.
 */
error ProofOfIdentity__IsNotVerified(address account);

/**
 * @notice Raised when an attempt to issue an ID to an already verified account
 * is made.
 *
 * @param account The address of the already verified account.
 */
error ProofOfIdentity__IsVerified(address account);

/**
 * @notice Raised when an attempt is made to update the token URI for an invalid
 * account <> token ID pairing.
 *
 * @param owner     The owner address.
 * @param supplied  The supplied address.
 */
error ProofOfIdentity__IsNotOwner(address owner, address supplied);

/**
 * @notice Raised when an attempt to transfer a Proof of Identity NFT is made.
 */
error ProofOfIdentity__IDNotTransferable();

/**
 * @notice Raised when an invalid token ID has been supplied.
 * @param tokenID The supplied token ID.
 */
error ProofOfIdentity__InvalidTokenID(uint256 tokenID);

/**
 * @notice Raised when an unauthorized account attempts to access a feature
 * requiring a principal Proof of Identity NFT.
 */
error ProofOfIdentity__PrincipalRequired();

/**
 * @notice Raised when an attempt is made to issue an auxiliary Proof of
 * Identity NFT to account that has reached the limit.
 */
error ProofOfIdentity__MaxAuxiliaryReached();

/**
 * @notice Raised when an attempt is made to issue an auxiliary Proof of
 * Identity NFT to account that is suspended.
 *
 * @param addr The address that is suspended.
 */
error ProofOfIdentity__IsSuspended(address addr);
