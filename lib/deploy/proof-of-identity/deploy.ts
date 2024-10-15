/* IMPORT NODE MODULES
================================================== */
import { ethers, upgrades } from "hardhat";

/* IMPORT TYPES
================================================== */
import type { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import type { ProofOfIdentity } from "@typechain";

/* TYPES
================================================== */
/**
 * The args required to initialise the `ProofofIdentity` contract.
 */
export type ProofOfIdentityArgs = {
    readonly association: string;
    readonly permissionsInterface: string;
    readonly accountManager: string;
    readonly networkGuardianController: string;
};

/**
 * The supported Proof of Identity Attribute IDs and their string name.
 */
type AttributeType = {
    readonly id: number;
    readonly str: "bool" | "string" | "uint256" | "bytes";
};

/**
 * Represents a Proof of Identity Attribute.
 */
type Attribute = {
    readonly id: number;
    readonly name: string;
    readonly attrType: AttributeType;
};

/**
 * The string representation of the Proof of Identity types.
 */
type POIType = "NOT_ISSUED" | "PRINCIPAL" | "AUXILIARY";

/* CONSTANTS
================================================== */
/**
 * Mapping of supported attribute types to their enum value.
 */
export const SUPPORTED_ID_ATTR_TYPES = {
    STRING: { id: 0, str: "string" },
    BOOL: { id: 1, str: "bool" },
    U256: { id: 2, str: "uint256" },
    BYTES: { id: 3, str: "bytes" },
} as const satisfies Record<string, AttributeType>;

/**
 * Mapping of attributes to their ID and names.
 */
export const PROOF_OF_ID_ATTRS = {
    PRIMARY_ID: {
        id: 0,
        name: "primaryID",
        attrType: SUPPORTED_ID_ATTR_TYPES.BOOL,
    },
    COUNTRY_CODE: {
        id: 1,
        name: "countryCode",
        attrType: SUPPORTED_ID_ATTR_TYPES.STRING,
    },
    PROOF_OF_LIVELINESS: {
        id: 2,
        name: "proofOfLiveliness",
        attrType: SUPPORTED_ID_ATTR_TYPES.BOOL,
    },
    USER_TYPE: {
        id: 3,
        name: "userType",
        attrType: SUPPORTED_ID_ATTR_TYPES.U256,
    },
    COMPETENCY_RATING: {
        id: 4,
        name: "competencyRating",
        attrType: SUPPORTED_ID_ATTR_TYPES.U256,
    },
    NATIONALITY: {
        id: 5,
        name: "nationality",
        attrType: SUPPORTED_ID_ATTR_TYPES.STRING,
    },
    ID_ISSUING_COUNTRY: {
        id: 6,
        name: "idIssuingCountry",
        attrType: SUPPORTED_ID_ATTR_TYPES.STRING,
    },
} as const satisfies Record<string, Attribute>;

/**
 * Mapping of POI Type to its enum value.
 */
export const POI_TYPE = {
    NOT_ISSUED: 0n,
    PRINCIPAL: 1n,
    AUXILIARY: 2n,
} as const satisfies Record<POIType, bigint>;

/* DEPLOY
================================================== */
/**
 * Deploys the `ProofofIdentity` contract.
 *
 * # Error
 *
 * Will throw an error if the deployment is not successful. The calling code
 * must handle as desired.
 *
 * @async
 * @throws
 * @function    deployProofOfIdentity
 *
 * @param       {ProofOfIdentityArgs}       args
 * @param       {HardhatEthersSigner}       signer
 * @param       {number}                    [confs = 0]
 *
 * @returns     {Promise<ProofOfIdentity>}  Promise that resolves to the `ProofOfIdentity` contract.
 */
export async function deployProofOfIdentity(
    args: ProofOfIdentityArgs,
    signer: HardhatEthersSigner,
    confs: number = 0
): Promise<ProofOfIdentity> {
    // -------------------------------------------------------------------------
    // Deploy
    const f = await ethers.getContractFactory("ProofOfIdentity", signer);

    const c = (await upgrades.deployProxy(
        f,
        [
            args.association,
            args.permissionsInterface,
            args.accountManager,
            args.networkGuardianController,
        ],
        { kind: "uups", initializer: "initialize" }
    )) as unknown as ProofOfIdentity;

    await c.waitForDeployment();

    if (confs > 0) {
        await c.deploymentTransaction()?.wait(confs);
    }

    // -------------------------------------------------------------------------
    // Set attribute counts

    const setCountRes = await c.setAttributeCount(
        Object.keys(PROOF_OF_ID_ATTRS).length
    );

    if (confs > 0) {
        await setCountRes.wait(confs);
    }

    // -------------------------------------------------------------------------
    // Set maximum auxiliary amount

    const setMaxAuxRes = await c.setMaxAux(100);
    if (confs > 0) {
        await setMaxAuxRes.wait(confs);
    }

    // -------------------------------------------------------------------------
    // Set initial attribute names and types

    // Has to be done like this, (rather than calling addAttribute) so that we
    // can ensure the correct ordering upon deployment.
    for (const { id, name, attrType } of Object.values(PROOF_OF_ID_ATTRS)) {
        let txRes = await c.setAttributeName(id, name);
        if (confs > 0) {
            await txRes.wait(confs);
        }

        txRes = await c.setAttributeType(id, attrType.id);

        if (confs > 0) {
            await txRes.wait(confs);
        }
    }

    // -------------------------------------------------------------------------
    // Return
    return c;
}
