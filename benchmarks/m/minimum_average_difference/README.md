# Minimum Average Difference

For each split after an array position, compare the integer average of the prefix with the integer average of the remaining suffix. Return the earliest index with the smallest absolute difference, matching the pinned C LeetCode 2256 implementation.

## Contract

- Input is an array of 1 through 100,000 values, each from 0 through 100,000.
- A split's averages use integer division that truncates toward zero. The suffix average is zero when the split is after the final value. Invalid lengths or values return `-1`.
- The input is read only. Ties return the first index.
- Each implementation first totals the array, then scans prefixes while tracking the best difference. Time is O(n); auxiliary space is O(1).

## Workload and verification

[`workload.json`](workload.json) covers singleton, uniform, increasing, example, and large-value arrays. [`benchmarks/verify_minimum_average_difference.py`](../../verify_minimum_average_difference.py) checks all nine implementations against an independent prefix/suffix oracle, including exhaustive small arrays, deterministic random arrays, the maximum input length, and malformed values.

## Upstream source

- [TheAlgorithms/C LeetCode 2256](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/2256.c)
