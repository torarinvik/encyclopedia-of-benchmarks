# Subset Sum Dynamic Programming

This package ports the pinned C++ `subset_sum_problem` implementation and the C-Plus-Plus-1 `dynamic_programming/subset_sum.cpp` variant. Both decide whether an indexed subset reaches a target with top-down include/exclude recursion and memoization keyed by item index and remaining target.

## Contract

- The `i64_array_scalar` input is `[target, item0, item1, ...]`; a target with no items is valid.
- The target is bounded to `[-80, 80]`, with at most 16 items, each in `[-20, 20]`.
- Return `1` if some subset reaches the target and `0` otherwise. The empty subset makes target zero reachable. Duplicate values represent distinct indexed choices.
- Invalid length or values return `-1`.

The bounded state keeps the memo table small while including signed targets and items from the pinned C++ source. The source short-circuits when the remaining target reaches zero, then checks the include branch before the exclude branch.

[`workload.json`](workload.json) contains representative, boundary, signed-value, and invalid-input cases. The runner oracle checks each expected result against the same include/exclude recurrence with memoization.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/subset_sum_dynamic.c`](../../../c/s/subset_sum_dynamic.c) |
| C3 | [`c3/s/subset_sum_dynamic.c3`](../../../c3/s/subset_sum_dynamic.c3) |
| C++ | [`cpp/s/subset_sum_dynamic.cpp`](../../../cpp/s/subset_sum_dynamic.cpp) |
| Elisa | [`elisa/s/subset_sum_dynamic.elisa`](../../../elisa/s/subset_sum_dynamic.elisa) |
| Nim | [`nim/s/subset_sum_dynamic.nim`](../../../nim/s/subset_sum_dynamic.nim) |
| Odin | [`odin/s/subset_sum_dynamic.odin`](../../../odin/s/subset_sum_dynamic.odin) |
| Rust | [`rust/s/subset_sum_dynamic.rs`](../../../rust/s/subset_sum_dynamic.rs) |
| V | [`v/s/subset_sum_dynamic.v`](../../../v/s/subset_sum_dynamic.v) |
| Zig | [`zig/s/subset_sum_dynamic.zig`](../../../zig/s/subset_sum_dynamic.zig) |

## Upstream source

- [TheAlgorithms/C-Plus-Plus `subset_sum_dynamic.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/dynamic_programming/subset_sum_dynamic.cpp)
- [TheAlgorithms/C-Plus-Plus-1 `subset_sum.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/dynamic_programming/subset_sum.cpp)
