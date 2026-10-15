# H-Index

Return the greatest integer `h` for which at least `h` papers each have at least `h` citations.

## Contract

- Input is a read-only array containing 0 to 5,000 citation counts, each in `0..=1000`.
- Return the H-index. The empty array returns 0; an invalid length or citation count returns -1.
- Inputs are not modified.
- The ports binary-search the possible H-index and count citations meeting each midpoint. This takes O(n log(min(n, 1000))) time and O(1) extra space.

## Reviewed source

The pinned [C LeetCode 274 source](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/274.c) sorts the citation array with `qsort` and scans from the largest value. The shared benchmark ABI supplies read-only input, so these ports use binary search over the same H-index definition rather than mutating the array. The published LeetCode bounds are 1 to 5,000 papers and 0 to 1,000 citations; this benchmark additionally defines empty input as 0 and invalid values as -1 ([problem statement](https://leetcode.com/problems/h-index/)).

## Workload and verification

[`workload.json`](workload.json) includes the published examples, threshold cases, invalid values, and a 5,000-paper input. [`benchmarks/verify_h_index.py`](../../verify_h_index.py) compares the ports with an independent sorting oracle and exhaustive/randomized inputs.

Build with the shared `i64_array_scalar` ABI and record with `benchmarks/run_i64_array_scalar.py`.
