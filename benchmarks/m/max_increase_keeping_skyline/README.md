# Max Increase to Keep City Skyline

Given a square grid of building heights, return the largest total increase that keeps the skyline unchanged when viewed from every row and column. Each building can rise to the smaller of its row maximum and column maximum.

## Contract

- Input is a signed 64-bit integer array: the first element is the grid dimension `n`, followed by `n × n` heights in row-major order.
- The grid dimension is 2 through 50, and each height is 0 through 100.
- Return the sum of all allowable height increases. Return -1 for an invalid dimension, array length, or height.
- The implementation collects row and column maxima, then sums the permissible increase for each cell in O(n²) time and O(n) auxiliary space.

## Workload and verification

[`workload.json`](workload.json) covers a published example, small and flat grids, invalid inputs, and a maximum-size grid. [`benchmarks/verify_max_increase_keeping_skyline.py`](../../verify_max_increase_keeping_skyline.py) checks the ports against a Python oracle on exhaustive small grids, deterministic random grids, boundary inputs, and every workload case.

## Reviewed source

The pinned C [LeetCode 807 implementation](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/807.c) computes row and column maxima before summing per-cell increases.

## Implementations

All nine ports use the shared i64-array/scalar ABI.
