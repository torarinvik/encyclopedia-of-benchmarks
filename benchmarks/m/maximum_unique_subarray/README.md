# Maximum Unique Subarray

This benchmark implements the C LeetCode 1695 sliding-window algorithm from TheAlgorithms/C. It returns the largest sum of a contiguous subarray that contains no repeated value.

The contract accepts 0 to 256 values in 1..10,000. Empty input returns 0; invalid values return -1. The ports track each value’s most recent position and update the active window in linear time.

The verifier exhausts arrays through length seven over values 1 through 4, adds seeded random inputs and invalid values, and checks maximum-length and collision-heavy inputs against an independent Python set-based sliding window. The pinned source is [TheAlgorithms/C LeetCode 1695](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/1695.c). Run the verifier with the Elisa stage1 compiler path supplied.
