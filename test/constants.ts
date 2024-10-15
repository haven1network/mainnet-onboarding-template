/** One day in seconds. */
export const DAY_SEC = 86_400;

/** One week in seconds. */
export const WEEK_SEC = DAY_SEC * 7;

/** One year in seconds. */
export const YEAR_SEC = DAY_SEC * 365;

/** The zero, or null, address. */
export const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

/** The dead address */
export const DEAD_ADDRESS = "0x000000000000000000000000000000000000dEaD";

/** Null address used to represent native H1 */
export const H1_ADDRESS = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";

/** The interface ID for ERC721. */
export const ERC_721_INTERFACE_ID = "0x80ac58cd";

/** The interface ID for ERC1155. */
export const ERC_1155_INTERFACE_ID = "0xd9b67a26";

/** Collection of Access Control revert messages. */
const ACCESS_CONTROL_ERROR = {
    MISSING_ROLE:
        /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/,
} as const satisfies Record<string, RegExp>;

type AccessControlErrorKey = keyof typeof ACCESS_CONTROL_ERROR;

/**
 * Function to return the regex for OZ `AccessControl` reversion messages.
 *
 * @function accessControlErr
 *
 * @param   {AccessControlErrorKey} err
 *
 * @returns {RegExp}
 */
export function accessControlErr(err: AccessControlErrorKey): RegExp {
    return ACCESS_CONTROL_ERROR[err];
}

/** Collection of Initializable revert messages. */
const INITIALIZBLE_ERRORS = {
    ALREADY_INITIALIZED: "Initializable: contract is already initialized",
    IS_INITIALIZING: "Initializable: contract is initializing",
    NOT_INITIALIZING: "Initializable: contract is not initializing",
} as const satisfies Record<string, string>;

type InitializableError = keyof typeof INITIALIZBLE_ERRORS;

/**
 * Function to return an error message associated with the OZ `Initializalbe`
 * contract.
 *
 * @function initialiazbleErr
 * @param   {InitializableError} err
 * @returns {string}
 */
export function initialiazbleErr(err: InitializableError): string {
    return INITIALIZBLE_ERRORS[err];
}

type H1DevelopedErrorKey = keyof typeof H1_DEVELOPED_ERROR;

/** Collection of H1 Developed Application error  messages. */
const H1_DEVELOPED_ERROR = {
    TRANSFER_FAILED: "H1Developed__FeeTransferFailed",
    INVALID_ADDRESS: "H1Developed__InvalidAddress",
    INSUFFICIENT_FUNDS: "H1Developed__InsufficientFunds",
    ARRAY_LENGTH_MISMATCH: "H1Developed__ArrayLengthMismatch",
    ARRAY_LENGTH_ZERO: "H1Developed__ArrayLengthZero",
    OUT_OF_BOUNDS: "H1Developed__IndexOutOfBounds",
    INVALID_FN_SIG: "H1Developed__InvalidFnSignature",
    INVALID_FEE_AMT: "H1Developed__InvalidFeeAmount",
    REENTER: "H1Developed__ReentrantCall",
} as const satisfies Record<string, string>;

/**
 * Function to return an error message from the `H1DevelopedApplication`.
 *
 * @function h1DevelopedErr
 *
 * @param   {H1DevelopedErrorKey} err
 *
 * @returns {string}
 */
export function h1DevelopedErr(err: H1DevelopedErrorKey): string {
    return H1_DEVELOPED_ERROR[err];
}

type GuardianError = keyof typeof GUARDIAN_ERROR;

/** Collection of Network Guardian error  messages. */
const GUARDIAN_ERROR = {
    ALREADY_REGISTERED: "NetworkGuardian__AlreadyRegistered",
    PAUSED: "NetworkGuardian__Paused",
    NOT_PAUSED: "NetworkGuardian__NotPaused",
} as const satisfies Record<string, string>;

/**
 * Returns an error message from the `NetworkGuardian` contract.
 *
 * @function    guardianErr
 *
 * @param       {GuardianError}    err
 *
 * @returns     {string}
 */
export function guardianErr(err: GuardianError): string {
    return GUARDIAN_ERROR[err];
}

type GuardianControllerError = keyof typeof GUARDIAN_CONTROLLER_ERROR;

/** Collection of Network Guardian Controller error  messages. */
const GUARDIAN_CONTROLLER_ERROR = {
    ALREADY_REGISTERED: "NetworkGuardianController__AlreadyRegistered",
    UNSUPPORTED_INTERFACE: "NetworkGuardianController__UnsupportedInterface",
    MAX_ITER: "NetworkGuardianController__MaxIterations",
    INVALID_RANGE: "NetworkGuardianController__InvalidRange",
    ZERO_LENGTH: "NetworkGuardianController__ZeroLength",
    OUT_OF_BOUNDS: "NetworkGuardianController__IndexOutOfBounds",
    PAUSE_FAILED: "NetworkGuardianController__PauseFailed",
    UNPAUSE_FAILED: "NetworkGuardianController__UnpauseFailed",
} as const satisfies Record<string, string>;

/**
 * Returns an error message from the `NetworkGuardianController` contract.
 *
 * @function    guardianControllerErr
 *
 * @param       {GuardianControllerError}    err
 *
 * @returns     {string}
 */
export function guardianControllerErr(err: GuardianControllerError): string {
    return GUARDIAN_CONTROLLER_ERROR[err];
}

/** Collection of Address library error  messages. */
const ADDRESS_ERRORS = {
    ZERO_ADDRESS: "Address__ZeroAddress",
} as const satisfies Record<string, string>;

type AddressError = keyof typeof ADDRESS_ERRORS;

/**
 * Function to return an error message associated with the `Address` library.
 *
 * @function addressErr
 * @param   {AddressError} err
 * @returns {string}
 */
export function addressErr(err: AddressError): string {
    return ADDRESS_ERRORS[err];
}
