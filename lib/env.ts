type TransformFn<T> = (v: string) => T;

/**
 * Retrieves an environment variable by key. Will throw an error if not found.
 *
 * @throws
 * @function envExn
 *
 * @param   {string} key - The environment variable key.
 *
 * @returns {string} The value of the environment variable as a string.
 */
export function envExn(key: string): string;

/**
 * Retrieves an environment variable by key. Will throw an error if not found.
 * Transforms the variable using the provided function.
 *
 * @throws
 * @function envExn
 *
 * @param   {string}            key         The environment variable key.
 * @param   {TransformFn<T>}    transform   A function to transform the environment variable.
 *
 * @returns {T} The transformed environment value.
 */
export function envExn<T>(key: string, transform: TransformFn<T>): T;

export function envExn<T>(key: string, transform?: TransformFn<T>): T | string {
    const val = process.env[key];
    if (!val) {
        const err = `Required environment variable ${key} not found.`;
        throw new Error(err);
    }

    if (transform) {
        return transform(val);
    }

    return val;
}
