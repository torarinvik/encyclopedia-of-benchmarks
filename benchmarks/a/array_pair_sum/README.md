# Array Pair Sum

The pinned C LeetCode implementation sorts the values and sums the item at each even index. The portable ports preserve that strategy with a local copy and a shared heapsort procedure, so the input stays read-only and the sorting method is consistent across languages.

## Contract

- Input is an array of 0–4,096 signed 32-bit integers. Its length must be even.
- Sort ascending, pair adjacent values, and return the sum of each pair's smaller value. Empty input returns 0.
- Return `-1` for odd lengths, values outside signed 32-bit range, or inputs longer than 4,096.
- The implementation uses O(n log n) time and O(n) local storage. It relies on portable integer operations and a generic heapsort.

## Workload and verification

[`workload.json`](workload.json) covers negative and duplicate values, signed boundaries, invalid inputs, and maximum length. [`benchmarks/verify_array_pair_sum.py`](../../verify_array_pair_sum.py) compares each language with a sorting oracle over exhaustive short arrays, seeded random arrays, and boundary cases.

## Upstream source

- [TheAlgorithms/C LeetCode 561](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/561.c)
