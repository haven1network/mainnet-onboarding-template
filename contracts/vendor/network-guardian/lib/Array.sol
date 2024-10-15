// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import { NetworkGuardianController__ZeroLength, NetworkGuardianController__InvalidRange } from "./Errors.sol";

/**
 * @dev Start is inclusive, end is exclusive.
 */
struct Range {
    uint256 start;
    uint256 end;
}

library Array {
    /**
     * @notice Returns a list of ranges, split into `chunkSize` chunks.
     *
     * @param chunkSize The size of each chunk.
     * @param len       The total length to be divided into chunks.
     *
     * @return An array of `Range` structs representing the valid ranges.
     */
    function ranges(
        uint256 chunkSize,
        uint256 len
    ) internal pure returns (Range[] memory) {
        if (len <= chunkSize) {
            Range[] memory range = new Range[](1);
            range[0] = Range({ start: 0, end: len });
            return range;
        }

        // Length is now known to be greater than the chunk size.
        uint256 mod = len % chunkSize;
        uint256 rounds = len / chunkSize;
        uint256 rangeCount = rounds;

        uint256 start = 0;
        uint256 end = chunkSize;

        if (mod > 0) {
            rangeCount++;
            assert(rangeCount * chunkSize > len);
        }

        Range[] memory out = new Range[](rangeCount);

        for (uint256 i; i < rounds; i++) {
            Range memory range = Range({ start: start, end: end });
            out[i] = range;

            start = end;
            end = end + chunkSize;
        }

        if (mod > 0) {
            Range memory range = Range({ start: start, end: start + mod });
            out[rounds] = range;
        }

        return out;
    }

    /**
     * @notice Asserts that a given range is valid.
     *
     * @param start The start index.
     * @param end   The end index.
     * @param len   The length of the array.
     *
     * @dev Start is inclusive, end is exclusive.
     *
     * Requirements:
     * -    The length must be greater than zero.
     * -    Start must not be greater than end.
     * -    Start must not be greater than or equal to the length.
     * -    End must be greater than the length.
     */
    function assertValidRange(
        uint256 start,
        uint256 end,
        uint256 len
    ) internal pure {
        if (len == 0) {
            revert NetworkGuardianController__ZeroLength();
        }

        if (start > end || start >= len || end > len) {
            revert NetworkGuardianController__InvalidRange();
        }
    }
}
