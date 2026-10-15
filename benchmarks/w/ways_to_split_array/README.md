# Ways to Split Array

Count the split positions where the sum on the left is at least the sum on the right, using the prefix-sum scan from pinned C LeetCode 2270.

## Contract

- Input contains 2 through 100,000 signed values, each in `[-100,000, 100,000]`.
- A split is placed after an element and before the final element. It counts when `left_sum >= right_sum`. Invalid lengths or values return `-1`.
- The input is read only. The result is the number of qualifying split positions.
- Each implementation sums the array, then scans all valid prefix positions once. Time is O(n); auxiliary space is O(1).

## Workload and verification

[`workload.json`](workload.json) covers the LeetCode example, positive and negative values, equal sums, and a 512-value input. [`benchmarks/verify_ways_to_split_array.py`](../../verify_ways_to_split_array.py) checks all nine ports against an independent split oracle, including exhaustive short arrays, deterministic random arrays, maximum-length input, and malformed values.

## Upstream source

- [TheAlgorithms/C LeetCode 2270](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/2270.c)
