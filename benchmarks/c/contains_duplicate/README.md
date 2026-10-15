# Contains Duplicate

Implements the behavior of [TheAlgorithms/C LeetCode 217 source](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/217.c): return 1 when an integer array contains a repeated value, and 0 otherwise. The upstream implementation sorts the input and scans adjacent elements. These ports preserve that sort-and-scan algorithm using heapsort and a private copy, so callers' input remains unchanged and sorting does not rely on a platform-specific library implementation.

The shared ABI accepts at most 1,024 signed 32-bit values packed in an i64 array. Invalid lengths or values return -1. Empty and one-element arrays return 0. The algorithm takes O(n log n) time and O(n) additional storage for the private copy.

Run `python3 benchmarks/verify_contains_duplicate.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1` from the repository root to check all nine language ports against exhaustive, boundary, randomized, and published-workload cases.
