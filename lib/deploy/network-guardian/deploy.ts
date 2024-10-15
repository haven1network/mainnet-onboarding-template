/* IMPORT NODE MODULES
================================================== */
import { ethers, upgrades } from "hardhat";

/* IMPORT TYPES
================================================== */
import type { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import type { NetworkGuardianController } from "@typechain";

/* TYPES
================================================== */
/**
 * The args required to initialise the `NetworkGuardianController` contract.
 */
export type NetworkGuardianControllerArgs = {
    readonly association: string;
};

/**
 * The args required to initialise the `NetworkGuardian` contract.
 */
export type NetworkGuardianArgs = {
    readonly association: string;
    readonly controller: string;
};

/* DEPLOY
================================================== */
/**
 * Deploys the `NetworkGuardianController` contract.
 *
 * # Error
 *
 * Will throw an error if the deployment is not successful. The calling code
 * must handle as desired.
 *
 * @async
 * @throws
 * @function    deployGuardianController
 *
 * @param       {NetworkGuardianControllerArgs}         args
 * @param       {HardhatEthersSigner}                   signer
 * @param       {number}                                [confs = 0]
 *
 * @returns     {Promise<NetworkGuardianController>}    Promise that resolves to the `NetworkGuardianController` contract.
 */
export async function deployGuardianController(
    args: NetworkGuardianControllerArgs,
    signer: HardhatEthersSigner,
    confs: number = 0
): Promise<NetworkGuardianController> {
    const f = await ethers.getContractFactory(
        "NetworkGuardianController",
        signer
    );

    const c = (await upgrades.deployProxy(f, [args.association], {
        kind: "uups",
        initializer: "initialize",
    })) as unknown as NetworkGuardianController;

    await c.waitForDeployment();

    if (confs > 0) {
        await c.deploymentTransaction()?.wait(confs);
    }

    return c;
}
