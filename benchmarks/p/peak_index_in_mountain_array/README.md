# Peak Index in a Mountain Array

Find the index of the peak in a strict mountain array: values rise strictly to one interior peak and then fall strictly. The nine ports use binary search on the slope.

## Contract

- Accept strict mountain arrays of 3 to 100,000 signed 64-bit values. This extends the official nonnegative value range while preserving the same comparison-based algorithm.
- Return the interior peak index. Invalid lengths and monotone arrays return -1.
- The input must satisfy the strict mountain precondition. The algorithm takes O(log n) time and O(1) auxiliary space.

The pinned C source intends to binary-search adjacent values, but its upper bound can lead to a read past the final array element. The ports use the equivalent safe slope test at the midpoint and its successor.

## Workload and verification

[workload.json](workload.json) covers the published examples, early and late peaks, negative and signed-width values, invalid lengths, monotone inputs, and a maximum-length mountain. [benchmarks/verify_peak_index_in_mountain_array.py](../../verify_peak_index_in_mountain_array.py) compares the ports with a linear peak oracle on exhaustive short mountains, seeded random mountains, and boundary cases.

Run the command: python3 benchmarks/verify_peak_index_in_mountain_array.py --elisa-compiler /absolute/path/to/elisac.

## Reviewed source

- [TheAlgorithms/C LeetCode 852 source](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/852.c) and the [LeetCode problem statement](https://leetcode.com/problems/peak-index-in-a-mountain-array/)
