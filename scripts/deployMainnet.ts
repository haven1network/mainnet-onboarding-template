/**
 * @file This script handles deploying all the contracts in this project to the
 * Haven1 Mainnet.
 *
 * # Deployer Address
 * It assumes that the 0th indexed address in the `accounts` array is the
 * private key of the account that will be used to deploy the contracts.
 * E.g.
 *
 * ```typescript
 * // File: hardhat.config.ts
 *
 * const config: HardhatUserConfig = {
 *     networks: {
 *         haven_mainnet: {
 *             url: HAVEN_MAINNET_RPC,
 *             accounts: [MAINNET_DEPLOYER], // This account will deploy
 *         },
 *     },
 * }
 * ```
 */

/* IMPORT NODE MODULES
================================================== */
import { ethers } from "hardhat";

/* IMPORT CONSTANTS AND UTILS
================================================== */
import {
    type AuctionConfig,
    type NFTAuctionArgs,
    AuctionID,
    deployNFTAuction,
} from "@lib/deploy/nft-auction";

import {
    type SimpleStorageArgs,
    deploySimpleStorage,
} from "@lib/deploy/simple-storage";

import { d, tx } from "@lib/deploy/wrapper";
import { writeJSON } from "@lib/json";
import { WEEK_SEC } from "@test/constants";
import { envExn } from "@lib/env";
import { strToBigint } from "@lib/transform";

/* SCRIPT
================================================== */
async function main() {
    /* Setup
    ======================================== */
    const chainID = envExn("MAINNET_CHAIN_ID", strToBigint);
    const connectedChainID = (await ethers.provider.getNetwork()).chainId;

    if (chainID != connectedChainID) {
        const err = `Expected chain ID: ${chainID}. Got chain ID: ${connectedChainID}`;
        throw new Error(err);
    }

    const [deployer] = await ethers.getSigners();

    const association = envExn("MAINNET_ASSOCIATION");
    const dev = envExn("MAINNET_DEV");
    const devFeeCollector = envExn("MAINNET_DEV_FEE_COLLECTOR");
    const feeContract = envExn("MAINNET_FEE_CONTRACT");
    const poiContract = envExn("MAINNET_POI_CONTRACT");
    const controllerContract = envExn("MAINNET_GUARDIAN_CONTROLLER_CONTRACT");

    /* Simple Storage
    ======================================== */
    const simpleStorage = await d("Simple Storage", async function () {
        const fnSigs = ["incrementCount()", "decrementCount()"];
        const fnFees = [ethers.parseUnits("2", 18), ethers.parseUnits("1", 18)];

        const args: SimpleStorageArgs = {
            feeContract: feeContract,
            guardianController: controllerContract,
            association: association,
            developer: dev,
            feeCollector: devFeeCollector,
            fnSigs,
            fnFees,
            storesH1: false,
        };

        return await deploySimpleStorage(args, deployer, 2);
    });

    /* Mock NFT
    ======================================== */
    const mockNFT = await d("Mock NFT", async function () {
        const f = await ethers.getContractFactory("MockNFT", deployer);
        const c = await f.deploy(10_000);
        await c.waitForDeployment();
        await c.deploymentTransaction()?.wait(2);
        return c;
    });

    /* NFT AUCTION
    ======================================== */
    const auction = await d("NFT Auction", async function () {
        const nftID = 1n;
        const fnSigs = ["startAuction()", "bid()", "endAuction()"];
        const fnFees = [0n, ethers.parseUnits("2", 18), 0n];

        const config: AuctionConfig = {
            kind: AuctionID.ALL,
            length: BigInt(WEEK_SEC),
            startingBid: ethers.parseUnits("10", 18),
            nft: mockNFT.address,
            nftID,
            beneficiary: dev,
        };

        const args: NFTAuctionArgs = {
            proofOfIdentity: poiContract,
            feeContract: feeContract,
            guardianController: controllerContract,
            association: association,
            developer: dev,
            feeCollector: dev,
            fnSigs,
            fnFees,
            config,
        };

        return await deployNFTAuction(args, deployer, 2);
    });

    /* Additional Setup
    ======================================== */
    await tx(
        "Register the Simple Storage Contract with the Network Guardian Controller",
        async () => await simpleStorage.contract.register(),
        2
    );

    await tx(
        "Register the Auction Contract with the Network Guardian Controller",
        async () => await auction.contract.register(),
        2
    );

    await tx(
        "Mint the developer an NFT to use as the Auction prize",
        async () => await mockNFT.contract.mint(dev),
        2
    );

    /* Output
    ======================================== */
    const data = {
        simpleStorage: simpleStorage.address,
        mockNFT: mockNFT.address,
        auction: auction.address,
    } as const satisfies Record<string, string>;

    const path = "./deployment_data/mainnet/deployments.json";
    const success = writeJSON(path, data);

    if (!success) {
        console.error("Write to JSON failed");
    }
}

main().catch(error => {
    console.error(error);
    process.exitCode = 1;
});
