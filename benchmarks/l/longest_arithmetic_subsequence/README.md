# Longest arithmetic subsequence

This benchmark returns the length of the longest arithmetic subsequence in an integer array. A subsequence may skip elements; each adjacent difference in the chosen subsequence must be equal.

## Contract

- The `i64_array_scalar` input is a sequence of signed 64-bit integers. The supported source domain is values in `[-1,000,000, 1,000,000]` and at most 64 values. The bounded values keep every Java `int` difference exact.
- Empty input returns `0`; a singleton returns `1`, matching the pinned Java source.
- For arrays with at least two values, return the maximum length of a subsequence with constant adjacent difference. Repeated values are allowed and form a length-two-or-longer subsequence when their difference is zero.
- The shared ABI maps inputs outside the stated bounds to `-1`; this sentinel is a benchmark input mapping, not a Java source return value.

The pinned Java implementation keeps, for each ending index, the best length for each integer difference. The ports use the same per-index difference dynamic program with bounded open-addressed tables. Source: [Java `LongestArithmeticSubsequence`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/LongestArithmeticSubsequence.java).

## Workload

`workload.json` includes empty and singleton arrays, constant and strictly increasing sequences, negative values, a non-contiguous arithmetic subsequence, repeated differences, maximum supported length, and invalid value/length bounds.

Build and record with the `i64_array_scalar` ABI family and `benchmarks/run_i64_array_scalar.py`.
