# Missing Number

Ports the arithmetic-series algorithm from [TheAlgorithms/C LeetCode 268](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/268.c). For an array of n distinct integers drawn from 0 through n, it subtracts the observed sum from n(n+1)/2 to find the absent value.

The shared ABI accepts up to 1,024 values, validates that each value is unique and in range, and returns the missing value. An empty array returns 0. Malformed inputs return -1. The input is not modified. Runtime and auxiliary space are O(n); the space is used to validate uniqueness.

Run python3 benchmarks/verify_missing_number.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1 from the repository root to check all nine ports against exhaustive short arrays, randomized cases, boundaries, and the published workload.
