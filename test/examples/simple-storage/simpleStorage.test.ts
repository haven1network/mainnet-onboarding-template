/* IMPORT NODE MODULES
================================================== */
import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { parseUnits } from "ethers";

/* IMPORT CONSTANTS AND UTILS
================================================== */
import { TestDeployment } from "./setup";
import { accessControlErr, guardianErr, h1DevelopedErr } from "@test/constants";
import { fnSelector } from "@lib/fnSelector";

/* CONSTANTS
================================================== */
const DIR = {
    DECR: 0,
    INCR: 1,
    RESET: 2,
} as const;
const SCALE = 10n ** 18n;

const event = "Count";
const incrSig = "incrementCount()";
const incrSel = fnSelector(incrSig);

const decrSig = "decrementCount()";
const decrSel = fnSelector(decrSig);

const resetSig = "resetCount()";
const resetSel = fnSelector(resetSig);

/* TESTS
================================================== */
describe("H1 Developed Application - Simple Storage Example", function () {
    async function setup() {
        return await TestDeployment.create();
    }

    /* Deployment and Init
    ========================================*/
    describe("Deployment and Initialization", function () {
        it("Should have a deployment address", async function () {
            const t = await loadFixture(setup);
            const addr = t.simpleStorageAddress;
            expect(addr).to.have.length(42);
        });

        it("Should correctly set the function fees", async function () {
            const t = await loadFixture(setup);
            const c = t.simpleStorage;
            const fees = t.simpleStorageArgs.fnFees;
            const h1USD = await t.fee.contract.h1USD(); // Initial set as: 1 H1 = 1.5 USD.

            // The unadjusted USD fee should be the same figure that was set
            // upon deployment:
            // -    Increment: 2 USD
            // -    Decrement: 1 USD
            const incrFee = await c.getFnFeeUSD(incrSel);
            const decrFee = await c.getFnFeeUSD(decrSel);

            expect(incrFee).to.equal(fees[0]);
            expect(decrFee).to.equal(fees[1]);

            // The Simple Storage contract has not been made exempt from fees
            // under the Fee Contract, nor are its current fees outside the
            // allowable bounds set by the Fee Contract. This means that the
            // adjusted fee (that is, the fee denominated in H1 tokens) will
            // be equal to the USD fee amount multiplied by the current H1 USD
            // price, scaled to 18 decimals.
            const incrFeeAdj = await c.getFnFeeAdj(incrSel);
            const decrFeeAdj = await c.getFnFeeAdj(decrSel);

            expect(incrFeeAdj).to.equal((fees[0] * h1USD) / SCALE);
            expect(decrFeeAdj).to.equal((fees[1] * h1USD) / SCALE);
        });
    });

    /* Increment Count
    ========================================*/
    describe("Increment Count", function () {
        it("Should correctly increment the count", async function () {
            const t = await loadFixture(setup);
            const c = t.simpleStorage;
            const dev = c.connect(t.developer);

            const updatedFee = parseUnits("3.15", 18);
            const err = h1DevelopedErr("INSUFFICIENT_FUNDS");

            let count = await c.count();
            expect(count).to.equal(0n);

            // Increment the count, passing in the initially set fee.
            const initialFee = await c.getFnFeeAdj(incrSel);
            let txRes = await c.incrementCount({ value: initialFee });
            await txRes.wait();

            count = await c.count();
            expect(count).to.equal(1n);

            // Set a new fee on increment
            txRes = await dev.setFee(incrSig, updatedFee);
            await txRes.wait();

            // Increment the count, passing in the new fee
            const feeAdj = await c.getFnFeeAdj(incrSel);

            txRes = await c.incrementCount({ value: feeAdj });
            await txRes.wait();

            count = await c.count();
            expect(count).to.equal(2n);

            // Sanity check on calling increment with no fee.
            await expect(c.incrementCount())
                .to.be.revertedWithCustomError(c, err)
                .withArgs(0n, feeAdj);
        });

        it("Should revert if the contract is paused", async function () {
            const t = await loadFixture(setup);
            const c = t.simpleStorage;
            const err = guardianErr("PAUSED");

            const txRes = await c.guardianPause();
            await txRes.wait();

            await expect(c.incrementCount()).to.be.revertedWithCustomError(
                c,
                err
            );
        });

        it("Should emit a Count event", async function () {
            const t = await loadFixture(setup);
            const c = t.simpleStorage;
            const d = c.connect(t.developer);
            const addr = t.associationAddress;

            const fee = await d.getFnFeeAdj(incrSel);

            await expect(c.incrementCount({ value: fee }))
                .to.emit(c, event)
                .withArgs(addr, DIR.INCR, 1n, fee);
        });
    });

    /* Decrement Count
    ========================================*/
    describe("Decrement Count", function () {
        it("Should correctly decrement the count", async function () {
            const t = await loadFixture(setup);
            const c = t.simpleStorage;
            const d = c.connect(t.developer);

            const updatedFee = parseUnits("1.75", 18);
            const err = h1DevelopedErr("INSUFFICIENT_FUNDS");

            let count = await c.count();
            expect(count).to.equal(0n);

            // Increment the count, passing in the initially set fee.
            const incrFee = await c.getFnFeeAdj(incrSel);
            const decrFee = await c.getFnFeeAdj(decrSel);

            let txRes = await c.incrementCount({ value: incrFee });
            await txRes.wait();

            count = await c.count();
            expect(count).to.equal(1n);

            // Decrement the count, passing in the initially set fee.
            txRes = await c.decrementCount({ value: decrFee });
            await txRes.wait();

            count = await c.count();
            expect(count).to.equal(0n);

            // Update the decrement fee.
            txRes = await d.setFee(decrSig, updatedFee);
            await txRes.wait();

            // Decrement the count, passing in the updated fee.
            const feeAdj = await c.getFnFeeAdj(decrSel);

            txRes = await c.incrementCount({ value: incrFee });
            await txRes.wait();

            count = await c.count();
            expect(count).to.equal(1n);

            txRes = await c.decrementCount({ value: feeAdj });
            await txRes.wait();

            count = await c.count();
            expect(count).to.equal(0n);

            // Sanity check on decrementing with no fee.
            await expect(c.decrementCount())
                .to.be.revertedWithCustomError(c, err)
                .withArgs(0n, feeAdj);
        });

        it("Should return early if the count is already zero", async function () {
            // vars
            const t = await loadFixture(setup);
            const c = t.simpleStorage;

            const fee = await c.getFnFeeAdj(decrSel);
            let count = await c.count();
            expect(count).to.equal(0n);

            const txRes = await c.decrementCount({ value: fee });
            await txRes.wait();

            count = await c.count();
            expect(count).to.equal(0n);
        });

        it("Should revert if the contract is paused", async function () {
            const t = await loadFixture(setup);
            const c = t.simpleStorage;
            const err = guardianErr("PAUSED");

            const txRes = await c.guardianPause();
            await txRes.wait();

            await expect(c.decrementCount()).to.be.revertedWithCustomError(
                c,
                err
            );
        });

        it("Should emit a Count event", async function () {
            const t = await loadFixture(setup);
            const c = t.simpleStorage;
            const addr = t.associationAddress;

            const fee = parseUnits("1.5", 18);
            const incrFee = await c.getFnFeeAdj(incrSel);

            const txRes = await c.incrementCount({ value: incrFee });
            await txRes.wait();

            const count = await c.count();
            expect(count).to.equal(1n);

            await expect(c.decrementCount({ value: fee }))
                .to.emit(c, event)
                .withArgs(addr, DIR.DECR, 0n, fee);

            await txRes.wait();
        });
    });

    /* Reset Count
    ========================================*/
    describe("Reset Count", function () {
        it("Should correctly reset the count", async function () {
            const t = await loadFixture(setup);
            const d = t.simpleStorage.connect(t.developer);
            const rounds = 5;

            let count = await d.count();
            expect(count).to.equal(0n);

            const incrFee = await d.getFnFeeAdj(incrSel);
            const resetFee = await d.getFnFeeAdj(resetSel);

            for (let i = 0; i < rounds; ++i) {
                const txRes = await d.incrementCount({ value: incrFee });
                await txRes.wait();
            }

            count = await d.count();
            expect(count).to.equal(rounds);

            const txRes = await d.resetCount({ value: resetFee });
            await txRes.wait();

            count = await d.count();
            expect(count).to.equal(0n);
        });

        it("Should only allow an account with the role DEV_ADMIN_ROLE to reset the count ", async function () {
            const t = await loadFixture(setup);
            const d = t.simpleStorage.connect(t.developer);
            const u = d.connect(t.accounts[0]);
            const err = accessControlErr("MISSING_ROLE");

            const incrFee = await d.getFnFeeAdj(resetSel);

            // Case: no role
            await expect(u.resetCount({ value: incrFee })).to.be.revertedWith(
                err
            );

            // Case: has role
            await expect(d.resetCount({ value: incrFee })).to.not.be.reverted;
        });

        it("Should revert if the contract is paused", async function () {
            const t = await loadFixture(setup);
            const c = t.simpleStorage;
            const d = c.connect(t.developer);
            const err = guardianErr("PAUSED");

            const txRes = await c.guardianPause();
            await txRes.wait();

            const fee = await c.getFnFeeAdj(resetSel);

            await expect(
                d.resetCount({ value: fee })
            ).to.be.revertedWithCustomError(d, err);
        });
    });

    /* Get Count
    ========================================*/
    describe("Get Count", function () {
        it("Should correctly get the count", async function () {
            const t = await loadFixture(setup);
            const c = t.simpleStorage;
            const rounds = 10;

            const fee = await c.getFnFeeAdj(incrSel);

            let count = await c.count();
            expect(count).to.equal(0n);

            for (let i = 0; i < rounds; ++i) {
                const txRes = await c.incrementCount({ value: fee });
                await txRes.wait();
                count = await c.count();
                expect(count).to.equal(i + 1);
            }

            count = await c.count();
            expect(count).to.equal(rounds);
        });
    });
});
