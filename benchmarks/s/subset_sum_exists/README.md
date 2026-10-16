# Subset Sum Existence

Return whether a selection of input elements adds to a requested target. Elements are indexed, so duplicate values remain distinct choices. Signed values are supported.

## Contract

- The input is `[target, item0, ...]`; an input containing only the target is valid.
- There may be at most 24 items. Each item and the target must be in `[-6144, 6144]`, and each item must be in `[-256, 256]`.
- Return `1` when some subset sums to the target, including the empty subset for target zero; otherwise return `0`.
- Malformed or out-of-range input returns `-1`.
- The implementations use a one-dimensional signed-sum reachability table. Positive items update sums downward and negative items update sums upward, so each item is used at most once.

## Reviewed TheAlgorithms sources

The signed-existence mapping is the pinned [Rust backtracking implementation](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/backtracking/subset_sum.rs), which handles signed items and targets and treats target zero as reachable through the empty subset. The C++ backtracking files count matching indexed subsets and are mapped to [Subset Sum Count](../subset_sum_count/README.md). The signed C++ top-down memoized variants are mapped to [Subset Sum Dynamic Programming](../subset_sum_dynamic/README.md).

The Java, Go, R, and Rust dynamic-programming decision variants require nonnegative values and targets; they are mapped to the separate [Subset Sum Nonnegative Existence](../subset_sum_nonnegative_exists/README.md) contract. The R `find_all_subsets` routine returns value lists with positive-value pruning and is tracked separately from this signed positional-mask workload.

## Workload and verification

[`workload.json`](workload.json) contains named boundary and representative cases. [`benchmarks/verify_subset_sum.py`](../../verify_subset_sum.py) checks all nine ports against independent Python subset oracles on exhaustive short inputs, deterministic random inputs, malformed values, and every published workload case.

## Implementations

All nine implementations use the shared i64-array/scalar ABI and portable source-level arithmetic.
