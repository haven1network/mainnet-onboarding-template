/**
 * @file This script handles deploying all the contracts for this project to
 * the local node.
 *
 * # Addresses
 *
 * It assumes that the 0th indexed address in the `accounts` array is the
 * private key of the account that will be used to deploy the contracts.
 *
 * It assumes that the address at index one (1) in the `accounts` array is the
 * developer address.
 *
 * # Order of Deployments
 *
 * 1.   Mock Account Manager
 *
 * 2.   Mock Permissions Interface
 *
 * 3.   Network Guardian Controller
 *
 * 4.   Proof of Identity
 *
 * 5.   Fixed Fee Oracle
 *
 * 6.   Fee Contract
 *
 * 7.   Simple Storage
 *
 * 8.   MocK NFT - To be used as the prize in the NFT Auction
 *
 * 9.   NFT Auction
 *
 * # Extra Setup Steps
 *
 * After deployment, this script will mint the developer the NFT to be used as
 * the prize in the auction and approve the NFT Auction contract an allowance
 * over that NFT.
 */

/* IMPORT NODE MODULES
================================================== */
import { ethers } from "hardhat";

/* IMPORT CONSTANTS UTILS, AND TYPES
================================================== */
import { d, tx } from "@lib/deploy/wrapper";
import { WEEK_SEC } from "../test/constants";
import { writeJSON } from "@lib/json";

import {
    deployGuardianController,
    NetworkGuardianControllerArgs,
} from "@lib/deploy/network-guardian";

import {
    type ProofOfIdentityArgs,
    deployProofOfIdentity,
} from "@lib/deploy/proof-of-identity";

import { type FeeInitalizerArgs, deployFeeContract } from "@lib/deploy/fee";

import {
    type SimpleStorageArgs,
    deploySimpleStorage,
} from "@lib/deploy/simple-storage";

import {
    type AuctionConfig,
    type NFTAuctionArgs,
    AuctionID,
    deployNFTAuction,
} from "@lib/deploy/nft-auction";

/* SCRIPT
================================================== */
async function main() {
    /* Setup
    ======================================== */
    const [assoc, dev] = await ethers.getSigners();

    const assocAddr = await assoc.getAddress();
    const devAddr = await dev.getAddress();

    /* Mock Account Manager
    ======================================== */
    const accManager = await d("Account Manager", async function () {
        const f = await ethers.getContractFactory("MockAccountManager", assoc);
        const c = await f.deploy();
        return await c.waitForDeployment();
    });

    /* Mock Permissions Interface
    ======================================== */
    const permInterface = await d("Permissions Interface", async function () {
        const f = await ethers.getContractFactory(
            "MockPermissionsInterface",
            assoc
        );

        const c = await f.deploy(accManager.address);
        return await c.waitForDeployment();
    });

    /* Network Guardian Controller
    ======================================== */
    const controller = await d("Guardian Controller", async function () {
        const args: NetworkGuardianControllerArgs = {
            association: assocAddr,
        };

        return await deployGuardianController(args, assoc);
    });

    /* Proof of Identity
    ======================================== */
    const poi = await d("Proof of Identity", async function () {
        const args: ProofOfIdentityArgs = {
            association: assocAddr,
            networkGuardianController: controller.address,
            permissionsInterface: permInterface.address,
            accountManager: accManager.address,
        };

        return await deployProofOfIdentity(args, assoc);
    });

    /* Fixed Fee Oracle
    ======================================== */
    const oracle = await d("Fixed Fee Oracle", async function () {
        const startingVal = ethers.parseUnits("1.5", 18);

        const f = await ethers.getContractFactory("FixedFeeOracle", assoc);
        const c = await f.deploy(assocAddr, startingVal);
        return await c.waitForDeployment();
    });

    /* Fee Contract
    ======================================== */
    const fee = await d("Fee Contract", async function () {
        const args: FeeInitalizerArgs = {
            association: assocAddr,
            controller: controller.address,
            oracle: oracle.address,
            channels: [],
            weights: [],
            minDevFee: 0n, // $0 USD - no minimum fee.
            maxDevFee: ethers.parseUnits("5", 18), // $5 USD
            associationShare: ethers.parseUnits("0.2", 18), // 20%
            gracePeriod: 600,
        };

        return await deployFeeContract(args, assoc);
    });

    /* Simple Storage
    ======================================== */
    const simpleStorage = await d("Simple Storage", async function () {
        const fnSigs = ["incrementCount()", "decrementCount()"];
        const fnFees = [ethers.parseUnits("2", 18), ethers.parseUnits("1", 18)];

        const args: SimpleStorageArgs = {
            feeContract: fee.address,
            guardianController: controller.address,
            association: assocAddr,
            developer: devAddr,
            feeCollector: devAddr,
            fnSigs,
            fnFees,
            storesH1: false,
        };

        return await deploySimpleStorage(args, assoc);
    });

    /* Mock NFT
    ======================================== */
    const mockNFT = await d("Mock NFT", async function () {
        const f = await ethers.getContractFactory("MockNFT", assoc);
        const c = await f.deploy(10_000);
        return await c.waitForDeployment();
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
            beneficiary: devAddr,
        };

        const args: NFTAuctionArgs = {
            proofOfIdentity: poi.address,
            feeContract: fee.address,
            guardianController: controller.address,
            association: assocAddr,
            developer: devAddr,
            feeCollector: devAddr,
            fnSigs,
            fnFees,
            config,
        };

        return await deployNFTAuction(args, assoc);
    });

    /* Additional Setup
    ======================================== */
    await tx(
        "Register the Simple Storage Contract with the Network Guardian Controller",
        async () => await simpleStorage.contract.register(),
        0
    );

    await tx(
        "Register the Auction Contract with the Network Guardian Controller",
        async () => await auction.contract.register(),
        0
    );

    await tx(
        "Mint the developer an NFT to use as the Auction prize",
        async () => await mockNFT.contract.mint(devAddr),
        0
    );

    await tx(
        "Approve the NFT Auction contract and allowance over the prize NFT",
        async () =>
            await mockNFT.contract.connect(dev).approve(auction.address, 1n),
        0
    );

    /* Output
    ======================================== */
    const data = {
        accountManager: accManager.address,
        permissionsInterface: permInterface.address,
        guardianController: controller.address,
        proofOfIdentity: poi.address,
        oracle: oracle.address,
        feeContract: fee.address,
        simpleStorage: simpleStorage.address,
        mockNFT: mockNFT.address,
        auction: auction.address,
    } as const satisfies Record<string, string>;

    const path = "./deployment_data/local/deployments.json";
    const success = writeJSON(path, data);

    if (!success) {
        console.error("Write to JSON failed");
    }
}

main().catch(error => {
    console.error(error);
    process.exitCode = 1;
});
