# Squares of a Sorted Array

Given a nondecreasing integer array, return its squared values in nondecreasing order. The ports use the linear two-pointer method from the pinned C source: the largest absolute endpoint is squared into the next output slot from right to left.

## Contract

- Accept 0 to 10,000 signed integers in the range -10,000 through 10,000, sorted in nondecreasing order.
- Emit each square as a signed 64-bit little-endian value and return the number of output elements. Empty input returns 0.
- Return -1 for an invalid length, out-of-range value, or unsorted input. Return -2 if the caller's output buffer is too small.
- Preserve the input. The algorithm takes O(n) time and O(1) auxiliary space.

The upstream file contains two alternative functions with the same C name. The benchmark uses its two-pointer version and exposes the result through the common byte-output ABI.

## Workload and verification

[workload.json](workload.json) includes empty and single-element arrays, negative and positive values, equal-magnitude ties, the published bounds, an invalid order, and the maximum input length. [benchmarks/verify_squares_of_a_sorted_array.py](../../verify_squares_of_a_sorted_array.py) checks the nine ports against an independent sorting oracle, including exhaustive short nondecreasing arrays, seeded random cases, invalid values, and capacity handling.

Run the command: python3 benchmarks/verify_squares_of_a_sorted_array.py --elisa-compiler /absolute/path/to/elisac.

## Reviewed source

- [TheAlgorithms/C LeetCode 977 source](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/977.c) and the [LeetCode problem statement](https://leetcode.com/problems/squares-of-a-sorted-array/)
