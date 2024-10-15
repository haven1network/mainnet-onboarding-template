// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title FnSig
 *
 * @author The Haven1 Development Team
 *
 * @dev Library that provides helpers for function signatures stored as bytes.
 */
library FnSig {
    /**
     * @notice Decodes a given byte array `b` to a string. If the byte array
     * has no length, an empty string `""` is returned.
     *
     * @param b The byte array to decode.
     *
     * @return The string representation of `b`.
     */
    function toString(bytes memory b) internal pure returns (string memory) {
        if (b.length == 0) return "";
        return string(b);
    }

    /**
     * @notice Converts a given byte array to a function selector.
     * If the byte array has no length, an empty bytes4 array is returned.
     *
     * @param b The byte array to convert.
     *
     * @dev The provided byte array is expected to be a function signature.
     */
    function toFnSelector(bytes memory b) internal pure returns (bytes4) {
        if (b.length == 0) return bytes4("");
        return bytes4(keccak256(b));
    }
}
