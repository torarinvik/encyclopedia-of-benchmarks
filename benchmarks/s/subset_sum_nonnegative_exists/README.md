# Nonnegative Subset Sum Existence

This package covers the reviewed nonnegative subset-existence dynamic-programming cluster: Java `SubsetSum`, Java `SubsetSumSpaceOptimized`, the basic DP routine in R `subset_sum.r`, Go `IsSubsetSum`, and Rust `is_sum_subset`. The Go `subsetsum` candidate and Java space-optimized candidate are aliases of this contract. Each source asks whether a subset reaches the requested sum; this package returns only that Boolean result.

## Contract

- The `i64_array_scalar` input is `[target, item0, item1, ...]`; a target with no items is valid.
- The target and each item must be in `[0, 4096]`, with at most 64 items. These limits keep the source DP table and index arithmetic small; even the full two-dimensional table is at most 65 × 4097 cells.
- Return `1` if a subset reaches the target and `0` otherwise. The empty subset makes target zero reachable, including when the item list is empty. Duplicate values represent distinct indexed choices.
- Invalid length or values, including negative targets or items, return `-1`.
- The ports use descending subset-sum DP, so an item is used at most once. They keep the reachability vector to 4097 Boolean slots.

[`workload.json`](workload.json) includes target-zero and empty-input behavior, duplicates, zeros, exact and unreachable targets, the item-count boundary, and invalid values.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/subset_sum_nonnegative_exists.c`](../../../c/s/subset_sum_nonnegative_exists.c) |
| C3 | [`c3/s/subset_sum_nonnegative_exists.c3`](../../../c3/s/subset_sum_nonnegative_exists.c3) |
| C++ | [`cpp/s/subset_sum_nonnegative_exists.cpp`](../../../cpp/s/subset_sum_nonnegative_exists.cpp) |
| Elisa | [`elisa/s/subset_sum_nonnegative_exists.elisa`](../../../elisa/s/subset_sum_nonnegative_exists.elisa) |
| Nim | [`nim/s/subset_sum_nonnegative_exists.nim`](../../../nim/s/subset_sum_nonnegative_exists.nim) |
| Odin | [`odin/s/subset_sum_nonnegative_exists.odin`](../../../odin/s/subset_sum_nonnegative_exists.odin) |
| Rust | [`rust/s/subset_sum_nonnegative_exists.rs`](../../../rust/s/subset_sum_nonnegative_exists.rs) |
| V | [`v/s/subset_sum_nonnegative_exists.v`](../../../v/s/subset_sum_nonnegative_exists.v) |
| Zig | [`zig/s/subset_sum_nonnegative_exists.zig`](../../../zig/s/subset_sum_nonnegative_exists.zig) |

## Upstream source cluster

- [TheAlgorithms/Java `SubsetSum`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/SubsetSum.java)
- [TheAlgorithms/Java `SumOfSubset` recursion](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/SumOfSubset.java)
- [TheAlgorithms/Python `sum_of_subset.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/sum_of_subset.py)

The Java `SumOfSubset` recursive source is equivalent on nonnegative inputs but has exponential search; its practical input size is at most 24 items. It is source-mapped here for algorithm coverage, but the benchmark ports use bounded dynamic programming and do not execute that upstream Java routine.
- [TheAlgorithms/Java `SubsetSumSpaceOptimized`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/SubsetSumSpaceOptimized.java)
- [TheAlgorithms/R `subset_sum.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/dynamic_programming/subset_sum.r)
- [TheAlgorithms/Go `subsetsum.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/dynamic/subsetsum.go)
- [TheAlgorithms/Rust `subset_sum.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/dynamic_programming/subset_sum.rs)
