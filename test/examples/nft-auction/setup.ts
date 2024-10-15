/* IMPORT NODE MODULES
================================================== */
import { ethers } from "hardhat";
import { parseUnits } from "ethers";
import type { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import type { MockNFT, NFTAuction } from "@typechain/index";

/* IMPORT CONSTANTS AND UTILS
================================================== */
import { Fee, GuardianController, POI } from "../../utils";
import { WEEK_SEC } from "@test/constants";
import {
    type AuctionConfig,
    type NFTAuctionArgs,
    AuctionID,
    deployNFTAuction,
} from "@lib/deploy/nft-auction";

/* CONSTANTS AND UTILS
================================================== */
type AuctionErrorKey = keyof typeof AUCTION_ERRORS;

const AUCTION_ERRORS = {
    INVALID_AUCTION_KIND: "Auction__InvalidAuctionKind",
    INVALID_AUCTION_LENGTH: "Auction__InvalidAuctionLength",
    NOT_STARTED: "Auction__AuctionNotStarted",
    ACTIVE: "Auction__AuctionActive",
    FINISHED: "Auction__AuctionFinished",
    NO_ID: "Auction__NoIdentityNFT",
    SUSPENDED: "Auction__Suspended",
    ATTRIBUTE_EXPIRED: "Auction__AttributeExpired",
    USER_TYPE: "Auction__InvalidUserType",
    BID_TOO_LOW: "Auction__BidTooLow",
    IS_HIGHEST: "Auction__IsHighestBidder",
    TRANSFER_FAILER: "Auction__TransferFailed",
    ZERO_VALUE: "Auction__ZeroValue",
} as const satisfies Record<string, string>;

/**
 * Returns an error message from the `NFTAuction` contract.
 *
 * @function    auctionErr
 * @param       {AuctionErrorKey} err
 * @returns     {string}
 */
export function auctionErr(err: AuctionErrorKey): string {
    return AUCTION_ERRORS[err];
}

export const UserType = {
    RETAIL: 1,
    INSTITUTION: 2,
} as const;

/* TEST DEPLOY
================================================== */
/**
 * Creates a new instances of TestDeployment
 * @class   TestDeployment
 */
export class TestDeployment {
    /* Vars
    ======================================== */
    private _isInitialized: boolean;

    private _association!: HardhatEthersSigner;
    private _associationAddress!: string;

    private _developer!: HardhatEthersSigner;
    private _developerAddress!: string;

    private _accounts!: HardhatEthersSigner[];
    private _accountAddresses!: string[];

    private _fee!: Fee;
    private _guardianController!: GuardianController;
    private _poi!: POI;

    private _auctionContract!: NFTAuction;
    private _auctionContractAddress!: string;
    private _auctionArgs!: NFTAuctionArgs;

    private _nftContract!: MockNFT;
    private _nftContractAddress!: string;

    /* Init
    ======================================== */
    /**
     * Private constructor due to requirement for async init work.
     *
     * @constructor
     * @private
     */
    private constructor() {
        this._accounts = [];
        this._accountAddresses = [];

        this._isInitialized = false;
    }

    /**
     * Initializes `TestDeployment`. `isInitialized` will return false until
     * this is run.
     *
     * # Error
     *
     * Will throw if any of the deployments are not successful
     *
     * @private
     * @async
     * @method  init
     * @returns {Promise<TestDeployment>} - Promise that resolves to the `TestDeployment`
     * @throws
     */
    private async init(): Promise<TestDeployment> {
        // Accounts
        // ----------------------------------------
        const [association, developer, ...rest] = await ethers.getSigners();

        this._association = association;
        this._associationAddress = await association.getAddress();

        this._developer = developer;
        this._developerAddress = await developer.getAddress();

        for (let i = 0; i < rest.length; ++i) {
            this._accounts.push(rest[i]);
            this._accountAddresses.push(await rest[i].getAddress());
        }

        // Guardian Controller
        // ----------------------------------------
        this._guardianController = await GuardianController.create(
            { association: this._associationAddress },
            this._association
        );

        // Fee Contract
        // ----------------------------------------
        this._fee = await Fee.create(
            this._associationAddress,
            this._guardianController.address,
            this._association
        );

        // POI Contract
        // ----------------------------------------
        this._poi = await POI.create(
            this._associationAddress,
            this._guardianController.address,
            this._association
        );

        // NFT Contract
        // ----------------------------------------
        this._nftContract = await this.deployNFT();
        this._nftContractAddress = await this._nftContract.getAddress();

        await this._nftContract.mint(this._developerAddress);

        // Auction Contract
        // ----------------------------------------
        const fnSigs = ["startAuction()", "bid()", "endAuction()"];
        const fnFees = [0n, parseUnits("2", 18), 0n];
        const nftID = 1n;

        const config: AuctionConfig = {
            kind: AuctionID.ALL,
            length: BigInt(WEEK_SEC),
            startingBid: parseUnits("10", 18),
            nft: this._nftContractAddress,
            nftID,
            beneficiary: this._developerAddress,
        };

        this._auctionArgs = {
            proofOfIdentity: this._poi.address,
            feeContract: this._fee.address,
            guardianController: this._guardianController.address,
            association: this._associationAddress,
            developer: this._developerAddress,
            feeCollector: this._developerAddress,
            fnSigs,
            fnFees,
            config,
        };

        this._auctionContract = await deployNFTAuction(
            this._auctionArgs,
            association
        );

        this._auctionContractAddress = await this._auctionContract.getAddress();

        // Approve the Auction contract to transfer the NFT from the dev
        const txRes = await this._nftContract
            .connect(this._developer)
            .approve(this._auctionContractAddress, nftID);

        await txRes.wait();

        // Init
        // ----------------------------------------
        this._isInitialized = true;

        return this;
    }

    /**
     * Static method to create a new instance of `TestDeployment`. Runs required
     * init work and returns the instance.
     *
     * @public
     * @static
     * @async
     * @throws
     *
     * @method  create
     *
     * @returns {Promise<TestDeployment>}
     */
    public static async create(): Promise<TestDeployment> {
        const instance = new TestDeployment();
        return await instance.init();
    }

    /* Getters
    ======================================== */
    /**
     * @method      association
     * @returns     {HardhatEthersSigner}
     * @throws
     */
    public get association(): HardhatEthersSigner {
        this.validateInitialized("association");
        return this._association;
    }

    /**
     * @method      associationAddress
     * @returns     {string}
     * @throws
     */
    public get associationAddress(): string {
        this.validateInitialized("associationAddress");
        return this._associationAddress;
    }

    /**
     * @method      developer
     * @returns     {HardhatEthersSigner}
     * @throws
     */
    public get developer(): HardhatEthersSigner {
        this.validateInitialized("developer");
        return this._developer;
    }

    /**
     * @method      developerAddress
     * @returns     {string}
     * @throws
     */
    public get developerAddress(): string {
        this.validateInitialized("developerAddress");
        return this._developerAddress;
    }

    /**
     * @method      accounts
     * @returns     {HardhatEthersSigner[]}
     * @throws
     */
    public get accounts(): HardhatEthersSigner[] {
        this.validateInitialized("accounts");
        return this._accounts;
    }

    /**
     * @method      accountAddresses
     * @returns     {string[]}
     * @throws
     */
    public get accountAddresses(): string[] {
        this.validateInitialized("accountAddresses");
        return this._accountAddresses;
    }

    /**
     * @method      fee
     * @returns     {Fee}
     * @throws
     */
    public get fee(): Fee {
        this.validateInitialized("fee");
        return this._fee;
    }

    /**
     * @method      guardianController
     * @returns     {GuardianController}
     * @throws
     */
    public get guardianController(): GuardianController {
        this.validateInitialized("guardianController");
        return this._guardianController;
    }

    /**
     * @method      poi
     * @returns     {POI}
     * @throws
     */
    public get poi(): POI {
        this.validateInitialized("poi");
        return this._poi;
    }

    /**
     * @method      auction
     * @returns     {H1DevelopedSimpleStorage}
     * @throws
     */
    public get auction(): NFTAuction {
        this.validateInitialized("auction");
        return this._auctionContract;
    }

    /**
     * @method      auctionAddress
     * @returns     {string}
     * @throws
     */
    public get auctionAddress(): string {
        this.validateInitialized("auctionAddress");
        return this._auctionContractAddress;
    }

    /**
     * @method      auctionArgs
     * @returns     {NFTAuctionArgs}
     * @throws
     */
    public get auctionArgs(): NFTAuctionArgs {
        this.validateInitialized("auctionArgs");
        return this._auctionArgs;
    }

    /**
     * @method      nft
     * @returns     {MockNFT}
     * @throws
     */
    public get nft(): MockNFT {
        this.validateInitialized("nft");
        return this._nftContract;
    }

    /**
     * @method      nftAddress
     * @returns     {string}
     * @throws
     */
    public get nftAddress(): string {
        this.validateInitialized("nftAddress");
        return this._nftContractAddress;
    }

    /* Helpers
    ======================================== */

    /**
     * Deploys the NFT contract with a max supply of `10_000`.
     *
     * @method   deployNFT
     * @async
     * @public
     * @returns {Promise<MockNFT>}
     * @throws
     */
    public async deployNFT(): Promise<MockNFT> {
        const f = await ethers.getContractFactory("MockNFT");
        const c = await f.deploy(10_000);
        return await c.waitForDeployment();
    }

    /**
     *  Validates if the class instance has been initialized.
     *
     *  # Error
     *
     *  Will throw an error if the class instance has not been initialized.
     *
     *  @private
     *  @method     validateInitialized
     *  @param      {string}    method
     *  @throws
     */
    private validateInitialized(method: string): void {
        if (!this._isInitialized) {
            throw new Error(
                `Deployment not initialized. Call create() before accessing ${method}.`
            );
        }
    }
}
