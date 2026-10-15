# Find Minimum in Rotated Sorted Array

This benchmark finds the minimum value in a nonempty rotation of a strictly increasing array of up to 256 signed 64-bit integers. Values are distinct. Inputs outside the length bound return -1. The implementation uses binary search to narrow the minimum's position.

The pinned [TheAlgorithms/C LeetCode 153 source](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/153.c) compares the middle item with the high endpoint and returns the minimum value. Its source assumes a valid nonempty rotated array without duplicates.

The nine portable implementations use the shared `i64_array_scalar` ABI and live in each language's `f` folder. The verifier checks every rotation of short strictly increasing arrays, deterministic random arrays, signed 64-bit boundaries, and invalid lengths against a direct minimum oracle.

Build with `python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm find_min_rotated_sorted_array --language LANGUAGE` and record with `python3 benchmarks/run_i64_array_scalar.py --algorithm find_min_rotated_sorted_array`. Verify with `python3 benchmarks/verify_find_min_rotated_sorted_array.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1`.
