/* IMPORT NODE MODULES
================================================== */
import type {
    BaseContract,
    ContractTransactionResponse,
    ContractTransactionReceipt,
} from "ethers";

/* TYPES
================================================== */
export type DeploymentData<T> = {
    readonly contractName: string;
    readonly address: string;
    readonly hash: string;
    readonly nonce: number;
    readonly contract: T;
};

type Fn<T> = () => Promise<T>;
type TxFn = () => Promise<ContractTransactionResponse>;

/* DEPLOY WRAPPER
================================================== */
/**
 * Function that is a wrapper around any function that returns a type that
 * extends `BaseContract`.
 *
 * Useful for logging the results of a deployment to the console.
 * Returns a selection of data about the deployment.
 *
 * @function   d
 *
 * @param      {string}    contractName
 * @param      {Fn}        f
 *
 * @returns    {DeploymentData}
 */
export async function d<T extends BaseContract>(
    contractName: string,
    f: Fn<T>
): Promise<DeploymentData<T>> {
    console.log(`Deploying: ${contractName}\n`);

    const contract = await f();

    const address = await contract.getAddress();
    let hash = "";
    let nonce = 0;

    const t = contract.deploymentTransaction();
    if (t) {
        hash = t.hash;
        nonce = t.nonce;
    }

    console.table([
        { attr: "Hash", val: hash },
        { attr: "Address", val: address },
        { attr: "Nonce", val: nonce },
    ]);

    console.log("\nDeployment Completed\n");
    console.log("========================================\n");

    return { contractName, address, hash, nonce, contract };
}

/* TX WRAPPER
================================================== */

/*
 * Function that is a wrapper around any function that returns a
 * `ContractTransactionResponse`.
 *
 * Useful for logging the results of a transaction to the console.
 *
 * @function   tx
 *
 * @param      {string}     desc
 * @param      {Fn}         TxFn
 * @param      {number}     [confs=2]
 *
 * @returns    {ContractTransactionReceipt | null}
 */
export async function tx(
    desc: string,
    fn: TxFn,
    confs: number = 2
): Promise<ContractTransactionReceipt | null> {
    console.log(`Executing Transaction: ${desc}\n`);

    const txRes = await fn();
    const txRec = await txRes.wait(confs || 0);

    if (txRec) {
        console.table([
            { attr: "Hash", val: txRec.hash },
            { attr: "Nonce", val: txRes.nonce },
            { attr: "Confs", val: await txRec.confirmations() },
        ]);
    } else {
        console.table([
            { attr: "Hash", val: txRes.hash },
            { attr: "Nonce", val: txRes.nonce },
        ]);
    }

    console.log("\nTransaction Completed \n");
    console.log("========================================\n");

    return txRec;
}
