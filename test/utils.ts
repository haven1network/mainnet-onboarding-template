/* IMPORT NODE MODULES
================================================== */
import { ethers } from "hardhat";

import type { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import {
    parseUnits,
    type AddressLike,
    type BigNumberish,
    type ContractTransactionReceipt,
} from "ethers";
import type {
    FeeContract,
    FixedFeeOracle,
    MockAccountManager,
    MockPermissionsInterface,
    NetworkGuardianController,
    ProofOfIdentity,
} from "@typechain";

/* IMPORT CONSTANTS AND UTILS
================================================== */
import {
    type NetworkGuardianControllerArgs,
    deployGuardianController,
} from "@lib/deploy/network-guardian";
import {
    type ProofOfIdentityArgs,
    deployProofOfIdentity,
} from "@lib/deploy/proof-of-identity";
import { type FeeInitalizerArgs, deployFeeContract } from "@lib/deploy/fee";
import { addTime } from "@lib/time";

/* TYPES
================================================== */
type IssueIdArgs = {
    account: AddressLike;
    primaryID: boolean;
    countryCode: string;
    proofOfLiveliness: boolean;
    userType: BigNumberish;
    expiries: [BigNumberish, BigNumberish, BigNumberish, BigNumberish];
    tokenURI: string;
};

/* UTILS
================================================== */

/**
 * The `NetworkGuardianController` is a dependency for all contracts deployed
 * to the network. This class abstracts the deployment of the Network Guardian
 * Controller contract and exposes simple getters to help reduce boilerplate in
 * testing.
 */
export class GuardianController {
    /* Vars
    ======================================== */
    private _isInitialized: boolean;
    private _contract!: NetworkGuardianController;
    private _address!: string;
    private _args!: NetworkGuardianControllerArgs;

    /* Init
    ======================================== */

    /**
     * Private constructor due to requirement for async init work.
     *
     * @constructor
     * @private
     */
    private constructor() {
        this._isInitialized = false;
    }

    /**
     * Initializes the `GuardianController` instance.
     *
     * `isInitialized` will return false until this is run.
     *
     * # Error
     *
     * Will throw if any of the deployments are not successful.
     *
     * @private
     * @async
     * @throws
     * @method  init
     * @returns {Promise<GuardianController>}
     */
    private async init(
        args: NetworkGuardianControllerArgs,
        signer: HardhatEthersSigner
    ): Promise<GuardianController> {
        this._args = args;

        this._contract = await deployGuardianController(this._args, signer);
        this._address = await this._contract.getAddress();
        this._isInitialized = true;

        return this;
    }

    /**
     * Static method to create a new instance of `GuardianController`. Runs
     * required init work and returns the instance.
     *
     * @public
     * @static
     * @async
     * @throws
     *
     * @method  create
     *
     * @param   {NetworkGuardianControllerArgs} args
     * @param   {HardhatEthersSigner}           signer
     *
     * @returns {Promise<GuardianController>}
     */
    public static async create(
        args: NetworkGuardianControllerArgs,
        signer: HardhatEthersSigner
    ): Promise<GuardianController> {
        const instance = new GuardianController();
        return await instance.init(args, signer);
    }

    /* Getters
    ======================================== */

    /**
     * @method      contract
     * @returns     {NetworkGuardianController}
     * @throws
     */
    public get contract(): NetworkGuardianController {
        this.validateInitialized("contract");
        return this._contract;
    }

    /**
     * @method      address
     * @returns     {string}
     * @throws
     */
    public get address(): string {
        this.validateInitialized("address");
        return this._address;
    }

    /**
     * @method      args
     * @returns     {NetworkGuardianControllerArgs}
     * @throws
     */
    public get args(): NetworkGuardianControllerArgs {
        this.validateInitialized("args");
        return this._args;
    }

    /* Helpers
    ======================================== */
    /**
     * Validates if the class instance has been initialized.
     *
     * # Error
     *
     * Will throw an error if the class instance has not been initialized.
     *
     * @private
     * @method     validateInitialized
     * @param      {string}    method
     * @throws
     */
    private validateInitialized(method: string): void {
        if (!this._isInitialized) {
            throw new Error(
                `Deployment not initialized. Call create() before accessing ${method}.`
            );
        }
    }
}

/**
 * The `ProofOfIdentity` contract is a dependency for many contracts deployed
 * to the network. This class abstracts the deployment of the POI contract and
 * exposes simple getters to help reduce boilerplate in testing.
 */
export class POI {
    /* Vars
    ======================================== */
    private _isInitialized: boolean;
    private _contract!: ProofOfIdentity;
    private _address!: string;
    private _args!: ProofOfIdentityArgs;

    /* Init
    ======================================== */

    /**
     * Private constructor due to requirement for async init work.
     *
     * @constructor
     * @private
     */
    private constructor() {
        this._isInitialized = false;
    }

    /**
     * Initializes the `POI` instance.
     *
     * `isInitialized` will return false until this is run.
     *
     * # Error
     *
     * Will throw if any of the deployments are not successful.
     *
     * @private
     * @async
     * @throws
     * @method  init
     * @returns {Promise<POI>}
     * @throws
     */
    private async init(
        association: string,
        networkGuardianController: string,
        signer: HardhatEthersSigner
    ): Promise<POI> {
        // Account Manager
        // ----------------------------------------
        const accManager = await this.deployAccountManager();
        const accManagerAddr = await accManager.getAddress();

        // Permissions Interface
        // ----------------------------------------
        const permInterface = await this.deployPermInterface(accManagerAddr);
        const permInterfaceAddr = await permInterface.getAddress();

        // POI
        // ----------------------------------------
        this._args = {
            association,
            networkGuardianController,
            accountManager: accManagerAddr,
            permissionsInterface: permInterfaceAddr,
        };

        this._contract = await deployProofOfIdentity(this._args, signer);
        this._address = await this._contract.getAddress();

        // Init
        // ----------------------------------------
        this._isInitialized = true;

        return this;
    }

    /**
     * Static method to create a new instance of `POI`. Runs required init and
     * returns the instance.
     *
     * @public
     * @static
     * @async
     *
     * @method  create
     *
     * @param   {string}                association         The Haven1 Association address.
     * @param   {string}                guardianController  The Network Guardian Controller address.
     * @param   {HardhatEthersSigner}   signer              The deployer signer.
     *
     * @returns {Promise<POI>}
     */
    public static async create(
        association: string,
        guardianController: string,
        signer: HardhatEthersSigner
    ): Promise<POI> {
        const instance = new POI();
        return await instance.init(association, guardianController, signer);
    }

    /* Getters
    ======================================== */

    /**
     * @method      contract
     * @returns     {NetworkGuardianController}
     * @throws
     */
    public get contract(): ProofOfIdentity {
        this.validateInitialized("contract");
        return this._contract;
    }

    /**
     * @method      address
     * @returns     {string}
     * @throws
     */
    public get address(): string {
        this.validateInitialized("address");
        return this._address;
    }

    /**
     * @method      args
     * @returns     {ProofOfIdentityArgs}
     * @throws
     */
    public get args(): ProofOfIdentityArgs {
        this.validateInitialized("args");
        return this._args;
    }

    /* Helpers
    ======================================== */
    /**
     * Issues an ID and returns the transaction receipt.
     *
     * @async
     * @throws
     *
     * @method  issueIdentity
     *
     * @param   {IssueIdArgs}   args
     *
     * @returns {ContractTransactionReceipt | null}
     */
    public async issueIdentity(
        args: IssueIdArgs
    ): Promise<ContractTransactionReceipt | null> {
        this.validateInitialized("issueIdentity");
        const txRes = await this._contract.issueIdentity(
            args.account,
            args.primaryID,
            args.countryCode,
            args.proofOfLiveliness,
            args.userType,
            args.expiries,
            args.tokenURI
        );

        return await txRes.wait();
    }

    /**
     * Issues a default ID and returns the args.
     *
     * @async
     * @throws
     *
     * @method   issueDefaultIdentity
     *
     * @param   {AddressLike}   to
     *
     * @returns {IssueIdArgs}
     */
    public async issueDefaultIdentity(to: AddressLike): Promise<IssueIdArgs> {
        this.validateInitialized("issueIdentity");

        const args = this.defaultPOIArgs(to);

        const txRes = await this._contract.issueIdentity(
            args.account,
            args.primaryID,
            args.countryCode,
            args.proofOfLiveliness,
            args.userType,
            args.expiries,
            args.tokenURI
        );

        await txRes.wait();

        return args;
    }

    /**
     * Returns default ID Args.
     *
     * @method  defaultPOIArgs
     *
     * @param   {AddressLike}   to
     *
     * @returns {IssueIdArgs}
     */
    public defaultPOIArgs(to: AddressLike): IssueIdArgs {
        const ts = addTime(Date.now(), 1, "years", "sec");
        return {
            account: to,
            primaryID: true,
            countryCode: "sg",
            proofOfLiveliness: true,
            userType: 1,
            expiries: [ts, ts, ts, ts],
            tokenURI: "",
        } as const;
    }

    /**
     * @method   deployMockAccountManager
     * @returns {Promise<MockAccountManager>}
     */
    private async deployAccountManager(): Promise<MockAccountManager> {
        const f = await ethers.getContractFactory("MockAccountManager");
        const c = await f.deploy();
        return await c.waitForDeployment();
    }
    /**
     * @method   deployMockPermissionsInterface
     * @returns {Promise<MockPermissionsInterface>}
     */
    private async deployPermInterface(
        accountManager: string
    ): Promise<MockPermissionsInterface> {
        const f = await ethers.getContractFactory("MockPermissionsInterface");
        const c = await f.deploy(accountManager);
        return await c.waitForDeployment();
    }

    /**
     * Validates if the class instance has been initialized.
     *
     * # Error
     *
     * Will throw an error if the class instance has not been initialized.
     *
     * @private
     * @method     validateInitialized
     * @param      {string}    method
     * @throws
     */
    private validateInitialized(method: string): void {
        if (!this._isInitialized) {
            throw new Error(
                `Deployment not initialized. Call create() before accessing ${method}.`
            );
        }
    }
}

/**
 * The `FeeContract` contract is a dependency for many contracts deployed to
 * the network. This class abstracts the deployment of the Fee Contract and
 * exposes simple getters to help reduce boilerplate in testing.
 */
export class Fee {
    /* Vars
    ======================================== */
    private _isInitialized: boolean;
    private _contract!: FeeContract;
    private _address!: string;
    private _args!: FeeInitalizerArgs;

    /* Init
    ======================================== */

    /**
     * Private constructor due to requirement for async init work.
     *
     * @constructor
     * @private
     */
    private constructor() {
        this._isInitialized = false;
    }

    /**
     * Initializes the `Fee` instance.
     *
     * `isInitialized` will return false until this is run.
     *
     * # Error
     *
     * Will throw if any of the deployments are not successful.
     *
     * @private
     * @async
     * @throws
     * @method  init
     * @returns {Promise<Fee>}
     */
    private async init(
        association: string,
        guardianController: string,
        signer: HardhatEthersSigner
    ): Promise<Fee> {
        // Oracle
        // ----------------------------------------
        const oracle = await this.deployOracle(association);
        const oracleAddress = await oracle.getAddress();

        // Fee Contract
        // ----------------------------------------
        this._args = {
            association,
            controller: guardianController,
            oracle: oracleAddress,
            channels: [],
            weights: [],
            minDevFee: 0n, // $0 USD - no minimum fee.
            maxDevFee: parseUnits("5", 18), // $5 USD
            associationShare: parseUnits("0.2", 18), // 20%
            gracePeriod: 600,
        };

        this._contract = await deployFeeContract(this._args, signer);
        this._address = await this._contract.getAddress();

        // Init
        // ----------------------------------------
        this._isInitialized = true;

        return this;
    }

    /**
     * Static method to create a new instance of `Fee`. Runs required init work
     * and returns the instance.
     *
     * The initial fee is set at 1 H1 = 1.5 USD.
     *
     * @public
     * @static
     * @async
     * @throws
     *
     * @method  create
     *
     * @param   {string}                association         The Haven1 Association address.
     * @param   {string}                guardianController  The Network Guardian Controller address.
     * @param   {HardhatEthersSigner}   signer              The deployer signer.
     *
     * @returns {Promise<Fee>}
     */
    public static async create(
        association: string,
        guardianController: string,
        signer: HardhatEthersSigner
    ): Promise<Fee> {
        const instance = new Fee();
        return await instance.init(association, guardianController, signer);
    }

    /* Getters
    ======================================== */

    /**
     * @method      contract
     * @returns     {Fee}
     * @throws
     */
    public get contract(): FeeContract {
        this.validateInitialized("contract");
        return this._contract;
    }

    /**
     * @method      address
     * @returns     {string}
     * @throws
     */
    public get address(): string {
        this.validateInitialized("address");
        return this._address;
    }

    /**
     * @method      args
     * @returns     {FeeInitalizerArgs}
     * @throws
     */
    public get args(): FeeInitalizerArgs {
        this.validateInitialized("args");
        return this._args;
    }

    /* Helpers
    ======================================== */
    /**
     * The initial fee is set at 1 H1 = 1.5 USD.
     *
     * @private
     * @async
     * @throws
     *
     * @method   deployOracle
     *
     * @param   {string} association
     *
     * @returns {Promise<FixedFeeOracle>}
     */
    private async deployOracle(association: string): Promise<FixedFeeOracle> {
        const f = await ethers.getContractFactory("FixedFeeOracle");
        const c = await f.deploy(association, parseUnits("1.5", 18));
        return await c.waitForDeployment();
    }

    /**
     * Validates if the class instance has been initialized.
     *
     * # Error
     *
     * Will throw an error if the class instance has not been initialized.
     *
     * @private
     * @method     validateInitialized
     * @param      {string}    method
     * @throws
     */
    private validateInitialized(method: string): void {
        if (!this._isInitialized) {
            throw new Error(
                `Deployment not initialized. Call create() before accessing ${method}.`
            );
        }
    }
}
