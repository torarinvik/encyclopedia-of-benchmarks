# First Bad Version

Given a monotone version predicate, find the first version marked bad.

## Contract

- Inputs are `version_count` and `first_bad`, with `1 <= first_bad <= version_count <= 2^31 - 1`.
- The modeled API returns true for versions at least `first_bad` and false for earlier versions.
- Return `first_bad` for valid inputs and -1 for invalid bounds.
- The implementation uses a lower-bound binary search, taking O(log version_count) time and O(1) extra space.

## Reviewed source

The pinned [C LeetCode 278 source](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/278.c) performs binary search by calling an external `isBadVersion` API. The benchmark makes that monotone API reproducible by passing its boundary as `first_bad`; testing the predicate becomes `middle >= first_bad`. The interval and overflow-safe midpoint follow the problem's bounds ([statement](https://leetcode.com/problems/first-bad-version/)).

## Workload and verification

[`workload.json`](workload.json) covers singleton, first, middle, and last bad versions, the maximum version count, and invalid bounds. [`benchmarks/verify_binary_scalar.py`](../../verify_binary_scalar.py) checks the ports against exhaustive small boundaries, large edge cases, and deterministic random version thresholds.

Build with the shared `binary_scalar` ABI and record with `benchmarks/run_binary_scalar.py`.
