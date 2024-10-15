/* IMPORT NODE MODULES
================================================== */
import { ethers } from "hardhat";
import type { AddressLike, TransactionReceipt } from "ethers";
import type { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

/* UTILS
================================================== */
/**
 * Sends H1 from the `from` signer to the `to` address.
 * The `amount` should be a plain decimal string, e.g., "159.13".
 *
 * # Errors
 * This function may error. It is up to the calling code to handle as desired.
 *
 * @async
 * @throws
 *
 * @function    sendH1
 *
 * @param       {HardhatEthersSigner}   from
 * @param       {AddressLike}           to
 * @param       {string}                amount
 * @param       {string}                [unencodedData]
 *
 * @returns     {Promise<TransactionReceipt | null>}
 */
export async function sendH1(
    from: HardhatEthersSigner,
    to: AddressLike,
    amount: string,
    unencodedData?: string
): Promise<TransactionReceipt | null> {
    const value = ethers.parseUnits(amount, 18);

    const data = unencodedData && ethers.encodeBytes32String(unencodedData);

    const tx = await from.sendTransaction({ to, value, data });
    return await tx.wait();
}

/**
 * Sends H1 from the `from` signer to the `to` address.
 *
 * The `amount` should be a bigint, pre-parsed.
 *
 * # Errors
 * This function may error. It is up to the calling code to handle as desired.
 *
 * @async
 * @throws
 *
 * @function    sendH1Bigint
 *
 * @param       {HardhatEthersSigner}   from
 * @param       {AddressLike}           to
 * @param       {bigint}                amount
 * @param       {string}                [unencodedData]
 *
 * @returns     {Promise<TransactionReceipt | null>}
 */
export async function sendH1Bigint(
    from: HardhatEthersSigner,
    to: AddressLike,
    amount: bigint,
    unencodedData?: string
): Promise<TransactionReceipt | null> {
    const data = unencodedData && ethers.encodeBytes32String(unencodedData);

    const tx = await from.sendTransaction({ to, value: amount, data });
    return await tx.wait();
}

/**
 * Wrapper around `signer.provider.getBalance`.
 *
 * # Errors
 * This function may error. It is up to the calling code to handle as desired.
 *
 * @async
 * @throws
 *
 * @function    getH1Balance
 *
 * @param       {AddressLike}           address
 * @param       {HardhatEthersSigner}   signer
 *
 * @returns     {Promise<bigint>}
 */
export async function getH1Balance(
    address: AddressLike,
    signer?: HardhatEthersSigner
): Promise<bigint> {
    signer ||= (await ethers.getSigners())[0];
    return await signer.provider.getBalance(address);
}
