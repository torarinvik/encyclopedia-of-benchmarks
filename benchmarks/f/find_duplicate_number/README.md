# Find the Duplicate Number

Return the repeated value in an array of `n + 1` integers whose values are in `1..=n`.

## Contract

- Valid input has 2 to 100,001 values and exactly one distinct repeated value; every value is in `1..=(length - 1)`.
- Return the repeated value. Invalid lengths or out-of-domain values return -1.
- The array is read-only; the implementation uses O(n) time and O(1) extra space.
- Floyd's tortoise-and-hare algorithm treats each array value as the next index, finds a cycle, then returns its entry.

## Reviewed source

The pinned [C LeetCode 287 source](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/287.c) sorts the array and scans adjacent values. The shared benchmark follows the problem's required linear runtime, constant extra space, and read-only input by using Floyd's cycle-entry method. The official constraints allow `n` up to 100,000 and require exactly one repeated value ([problem statement](https://leetcode.com/problems/find-the-duplicate-number/)).

## Workload and verification

[`workload.json`](workload.json) covers the published examples, small and maximum-length inputs, and malformed lengths or values. [`benchmarks/verify_find_duplicate_number.py`](../../verify_find_duplicate_number.py) checks exhaustive small permutations and randomized valid arrays against an independent frequency-count oracle.

Build with the shared `i64_array_scalar` ABI and record with `benchmarks/run_i64_array_scalar.py`. Large arrays stream through standard input so the runner can exercise all 100,001 values without a platform-specific command-line limit.
