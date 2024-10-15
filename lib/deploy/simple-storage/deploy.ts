/* IMPORT NODE MODULES
================================================== */
import { ethers, upgrades } from "hardhat";

/* IMPORT TYPES
================================================== */
import type { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import type { SimpleStorage } from "@typechain/index";

/* TYPES
================================================== */
export type SimpleStorageArgs = {
    readonly feeContract: string;
    readonly guardianController: string;
    readonly association: string;
    readonly developer: string;
    readonly feeCollector: string;
    readonly fnSigs: string[];
    readonly fnFees: bigint[];
    readonly storesH1: boolean;
};

/* DEPLOY
================================================== */
/**
 * Deploys the `Simple Storage` contract.
 *
 * # Error
 *
 * Will throw an error if the deployment is not successful. The calling code
 * must handle as desired.
 *
 * @async
 * @throws
 * @function    deploySimpleStorage
 *
 * @param       {SimpleStorageArgs}     args
 * @param       {HardhatEthersSigner}   signer
 * @param       {number}                [confs = 0]
 *
 * @returns     {Promise<SimpleStorage>}  Promise that resolves to the `SimpleStorage`.
 */
export async function deploySimpleStorage(
    args: SimpleStorageArgs,
    signer: HardhatEthersSigner,
    confs: number = 0
): Promise<SimpleStorage> {
    const f = await ethers.getContractFactory("SimpleStorage", signer);

    const c = (await upgrades.deployProxy(
        f,
        [
            args.feeContract,
            args.guardianController,
            args.association,
            args.developer,
            args.feeCollector,
            args.fnSigs,
            args.fnFees,
            args.storesH1,
        ],
        { kind: "uups", initializer: "initialize" }
    )) as unknown as SimpleStorage;

    await c.waitForDeployment();

    if (confs > 0) {
        await c.deploymentTransaction()?.wait(confs);
    }
    return c;
}
