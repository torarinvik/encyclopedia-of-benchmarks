# Maximum subarray with Kadane's algorithm

Return the greatest sum of any nonempty contiguous subarray using Kadane's linear scan. The algorithm keeps the best sum ending at the current position and the best sum seen so far.

## Contract

- Input is an array of signed 64-bit values with length 1 through 1,024.
- Each element must be in the signed 32-bit range.
- Return the maximum sum of a nonempty contiguous subarray.
- Empty, oversized, or out-of-range inputs return -1.

All valid sums fit in signed 64-bit arithmetic. This benchmark uses the same contract as the divide-and-conquer [max_subarray](../max_subarray/README.md) benchmark so the strategies can be compared on identical inputs.

## Workload and verification

The workload covers empty and singleton arrays, all-negative and mixed values, signed 32-bit boundaries, the maximum length, and invalid length and element values. [`verify_maximum_subarray.py`](../../verify_maximum_subarray.py) checks both strategies against an independent brute-force oracle on exhaustive short arrays, deterministic random arrays, boundaries, and all published cases.

## Reviewed TheAlgorithms sources

- C LeetCode [53](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/53.c) uses Kadane's scan.
- Rust [maximum_subarray](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/dynamic_programming/maximum_subarray.rs) and Ruby [maximum_subarray](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/arrays/maximum_subarray.rb) use the same nonempty-subarray recurrence.
- Python [max_subarray_sum](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/max_subarray_sum.py) defaults to disallowing empty subarrays and matches this contract.

C candidate `53` and Python candidate `max_subarray_sum` are cataloged as aliases of `maximum_subarray`.

## Implementations

All nine portable implementations use the shared i64-array/scalar ABI.
