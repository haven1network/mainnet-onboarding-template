# Testing

There are a number of setup steps that may be required for developers to effectively
test their contracts. For example, the `NetworkGuardianController`, `ProofOfIdentity`, and
`FeeContract` are contracts that often form dependencies of a testing suite. Similarly,
there are a number of actions that developers may need to repeat during their testing,
such as issuing Proof of Identity NFTs, fetching various smart contract error messages
or checking interface IDs.

The `constants.ts` and `utils.ts` file in the directory provide many of these features
for the developer so they do not have to worry about unnecessary boiler plate.

For example, `utils.ts` exports three helpful classes:
-   `GuardianContoller`: Abstracts the deployment of the Network Guardian Controller contract.
-   `POI`: Abstracts the deployment of the Proof of Identity contract and exposes a number of utilities to help with ID issuance.
-   `Fee`: Abstracts the deployment of the Fee Contract.

An example test suite setup file might look like this (note, you do not have to
use a class to setup your test environment - this is just an example):

```typescript
import { ethers } from "hardhat";
import type { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { Fee, GuardianController, POI } from "@test/utils";

export class TestSetup {
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

    /**
     * Private constructor due to requirement for async init work.
     */
    private constructor() {
        this._accounts = [];
        this._accountAddresses = [];

        this._isInitialized = false;
    }

    /**
     * Initializes `TestSetup`. `isInitialized` will return false until
     * this is run.
     *
     * # Error
     *
     * Will throw if any of the deployments are not successful
     *
     * @private
     * @async
     * @throws
     *
     * @method  init
     *
     * @returns {Promise<TestSetup>}
     */
    private async init(): Promise<TestSetup> {
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

        // Init
        // ----------------------------------------
        this._isInitialized = true;

        return this;
    }

    /**
     * Static method to create a new instance of `TestSetup`. Runs required
     * init work and returns the instance.
     *
     * @public
     * @static
     * @async
     * @throws
     *
     * @method  create
     *
     * @returns {Promise<TestSetup>}
     */
    public static async create(): Promise<TestSetup> {
        const instance = new TestSetup();
        return await instance.init();
    }

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

```

And could be called like this:

```typescript

const t = await TestSetup.create()

```

The `constants.ts` file exports a number of useful constants, such as interface IDs
and error messages.

For example, you may wish to check an error from the `H1DevelopedApplication`
contract as follows:

```typescript
import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";

import { TestSetup } from "./setup";
import { h1DevelopedErr } from "@test/constants";
import { fnSelector } from "@lib/fnSelector";

describe("My Test Suite", function () {
    async function setup() {
        return await TestSetup.create();
    }

    it("Should revert if the fee is insufficient", async function () {
        const t = await loadFixture(setup);

        const cDev = t.auction.connect(t.developer);
        const cUser = t.auction.connect(t.accounts[0]);
        const addr = t.accountAddresses[0];

        const bidSel = fnSelector("bid()");
        const fee = await cDev.getFnFeeAdj(bidSel);

        // -- Call into h1DevelopedErr to retrieve the custom error message -- //
        const errFunds = h1DevelopedErr("INSUFFICIENT_FUNDS");

        await t.poi.issueDefaultIdentity(addr);

        let txRes = await cDev.startAuction();
        await txRes.wait();

        const hasStarted = await cDev.hasStarted();
        expect(hasStarted).to.be.true;

        await expect(cUser.bid())
            .to.be.revertedWithCustomError(cUser, errFunds)
            .withArgs(0n, fee);
    });
});
```
