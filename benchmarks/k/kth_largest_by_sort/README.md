# Kth Largest Element by Full Sort

The pinned C LeetCode 215 source sorts all input values in descending order and returns position `k - 1`. The portable ports preserve the full-sort strategy with heapsort on a private copy, then select from the sorted result.

## Contract

- Input is `[k, value_0, value_1, ...]`.
- There are 1 through 512 signed 32-bit values, and `k` is from 1 through the number of values.
- Duplicate values count as separate positions. Inputs are read only; invalid inputs return `-1`.
- The result is the value at descending rank `k - 1`. The implementation uses O(n log n) time and O(n) space for the bounded local copy.

## Workload and verification

[`workload.json`](workload.json) covers first, middle, and last ranks, duplicates, negative values, signed 32-bit boundaries, sorted orders, and a 512-element input. [`benchmarks/verify_kth_largest.py`](../../verify_kth_largest.py) checks both the quickselect and full-sort benchmarks against an independent sorting oracle.

## Upstream source

- [TheAlgorithms/C LeetCode 215](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/215.c)
