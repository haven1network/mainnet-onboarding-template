/* IMPORT NODE MODULES
================================================== */
import { ethers } from "hardhat";
import { parseUnits } from "ethers";
import type { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import type { SimpleStorage } from "@typechain/index";

/* IMPORT CONSTANTS AND UTILS
================================================== */
import { Fee, GuardianController } from "../../utils";
import {
    deploySimpleStorage,
    SimpleStorageArgs,
} from "@lib/deploy/simple-storage/deploy";

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

    private _simpleStorageContract!: SimpleStorage;
    private _simpleStorageContractAddress!: string;
    private _simpleStorageArgs!: SimpleStorageArgs;

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

        // Simple Storage Contract
        // ----------------------------------------
        const fnSigs = ["incrementCount()", "decrementCount()"];
        const fnFees = [parseUnits("2", 18), parseUnits("1", 18)];

        this._simpleStorageArgs = {
            feeContract: this._fee.address,
            guardianController: this._guardianController.address,
            association: this._associationAddress,
            developer: this._developerAddress,
            feeCollector: this._developerAddress,
            fnSigs,
            fnFees,
            storesH1: false,
        };

        this._simpleStorageContract = await deploySimpleStorage(
            this._simpleStorageArgs,
            association
        );

        this._simpleStorageContractAddress =
            await this._simpleStorageContract.getAddress();

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
     * @method      simpleStorage
     * @returns     {H1DevelopedSimpleStorage}
     * @throws
     */
    public get simpleStorage(): SimpleStorage {
        this.validateInitialized("simpleStorage");
        return this._simpleStorageContract;
    }

    /**
     * @method      simpleStorageAddress
     * @returns     {string}
     * @throws
     */
    public get simpleStorageAddress(): string {
        this.validateInitialized("simpleStorageAddress");
        return this._simpleStorageContractAddress;
    }

    /**
     * @method      simpleStorageArgs
     * @returns     {H1DevStorageArgs}
     * @throws
     */
    public get simpleStorageArgs(): SimpleStorageArgs {
        this.validateInitialized("simpleStorageArgs");
        return this._simpleStorageArgs;
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
