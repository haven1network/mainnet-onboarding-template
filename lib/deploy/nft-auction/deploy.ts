/* IMPORT NODE MODULES
================================================== */
import { ethers, upgrades } from "hardhat";

/* IMPORT TYPES
================================================== */
import type { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import type { NFTAuction } from "@typechain/index";

/* TYPES
================================================== */
export type AuctionKind = (typeof AuctionID)[keyof typeof AuctionID];
export type NFTAuctionArgs = {
    readonly proofOfIdentity: string;
    readonly feeContract: string;
    readonly guardianController: string;
    readonly association: string;
    readonly developer: string;
    readonly feeCollector: string;
    readonly fnSigs: string[];
    readonly fnFees: bigint[];
    readonly config: AuctionConfig;
};

export type AuctionConfig = {
    readonly kind: AuctionKind;
    readonly length: bigint;
    readonly startingBid: bigint;
    readonly nft: string;
    readonly nftID: bigint;
    readonly beneficiary: string;
};

export const AuctionID = {
    RETAIL: 1,
    INSTITUTION: 2,
    ALL: 3,
} as const;

/* DEPLOY
================================================== */
/**
 * Deploys the `NFTAuction` contract.
 *
 * # Error
 *
 * Will throw an error if the deployment is not successful. The calling code
 * must handle as desired.
 *
 * @async
 * @throws
 * @function    deployNFTAuction
 *
 * @param       {NFTAuctionArgs}        args
 * @param       {HardhatEthersSigner}   signer
 * @param       {number}                [confs = 0]
 *
 * @returns     {Promise<NFTAuction>}  Promise that resolves to the `NFTAuction`.
 */
export async function deployNFTAuction(
    args: NFTAuctionArgs,
    signer: HardhatEthersSigner,
    confs: number = 0
): Promise<NFTAuction> {
    const f = await ethers.getContractFactory("NFTAuction", signer);

    const c = (await upgrades.deployProxy(
        f,
        [
            args.proofOfIdentity,
            args.feeContract,
            args.guardianController,
            args.association,
            args.developer,
            args.feeCollector,
            args.fnSigs,
            args.fnFees,
            args.config,
        ],
        { kind: "uups", initializer: "initialize" }
    )) as unknown as NFTAuction;

    await c.waitForDeployment();

    if (confs > 0) {
        await c.deploymentTransaction()?.wait(confs);
    }

    return c;
}
