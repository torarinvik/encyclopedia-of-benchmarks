# Subset Sum Existence

Return whether a selection of input elements adds to a requested target. Elements are indexed, so duplicate values remain distinct choices. Signed values are supported.

## Contract

- The input is `[target, item0, ...]`; an input containing only the target is valid.
- There may be at most 24 items. Each item and the target must be in `[-6144, 6144]`, and each item must be in `[-256, 256]`.
- Return `1` when some subset sums to the target, including the empty subset for target zero; otherwise return `0`.
- Malformed or out-of-range input returns `-1`.
- The implementations use a one-dimensional signed-sum reachability table. Positive items update sums downward and negative items update sums upward, so each item is used at most once.

## Reviewed TheAlgorithms sources

The pinned [C++ backtracking implementation](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/backtracking/subset_sum.cpp) and its duplicate in C-Plus-Plus-1 count matching subsets; the [C++ dynamic-programming implementation](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/dynamic_programming/subset_sum.cpp), [Java implementation](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/SubsetSum.java), [Go implementation](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/dynamic/subsetsum.go), and Rust backtracking/dynamic-programming implementations decide existence. The C++ dynamic variant, Java space-optimized variant, and Rust variants contribute alternate decision strategies for the same operation. R also provides subset enumeration in the reviewed `subset_sum.r` source; that output operation is tracked as a separate benchmark candidate.

## Workload and verification

[`workload.json`](workload.json) contains named boundary and representative cases. [`benchmarks/verify_subset_sum.py`](../../verify_subset_sum.py) checks all nine ports against independent Python subset oracles on exhaustive short inputs, deterministic random inputs, malformed values, and every published workload case.

## Implementations

All nine implementations use the shared i64-array/scalar ABI and portable source-level arithmetic.
