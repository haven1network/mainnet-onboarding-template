/* IMPORT NODE MODULES
================================================== */
import { ethers, upgrades } from "hardhat";

/* IMPORT TYPES
================================================== */
import type { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import type { BigNumberish } from "ethers";
import type { FeeContract } from "@typechain";

/* TYPES
================================================== */
export type FeeInitalizerArgs = {
    readonly association: string;
    readonly controller: string;
    readonly oracle: string;
    readonly channels: string[];
    readonly weights: BigNumberish[];
    readonly minDevFee: BigNumberish;
    readonly maxDevFee: BigNumberish;
    readonly associationShare: BigNumberish;
    readonly gracePeriod: BigNumberish;
};

/* DEPLOY
================================================== */
/**
 * Deploys the `FeeContract`.
 *
 * # Error
 *
 * Will throw an error if the deployment is not successful. The calling code
 * must handle as desired.
 *
 * @async
 * @throws
 * @function    deployFeeContract
 *
 * @param       {FeeInitalizerArgs}     args
 * @param       {HardhatEthersSigner}   signer
 * @param       {number}                [confs = 0]
 *
 * @returns     {Promise<FeeContract>}  Promise that resolves to the `FeeContract`.
 */
export async function deployFeeContract(
    args: FeeInitalizerArgs,
    signer: HardhatEthersSigner,
    confs: number = 0
): Promise<FeeContract> {
    const f = await ethers.getContractFactory("FeeContract", signer);

    const c = (await upgrades.deployProxy(
        f,
        [
            args.association,
            args.controller,
            args.oracle,
            args.channels,
            args.weights,
            args.minDevFee,
            args.maxDevFee,
            args.associationShare,
            args.gracePeriod,
        ],
        { kind: "uups", initializer: "initialize" }
    )) as unknown as FeeContract;

    await c.waitForDeployment();

    if (confs > 0) {
        await c.deploymentTransaction()?.wait(confs);
    }

    return c;
}
