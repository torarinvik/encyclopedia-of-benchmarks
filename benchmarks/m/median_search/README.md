# Median of medians selection

Return the element at zero-based rank `k` in an array of distinct integers. The benchmark calls the pinned source function `median_of_medians`; the source program's separate even-length median averaging is outside this selection contract.

## Contract

- The `i64_array_scalar` input is `[n, k, value_0, ..., value_(n-1)]`.
- `n` is 1 through 25, `k` is in `[0, n)`, and all `n` values are distinct integers in `[0, 2^31 - 1]`.
- A valid call returns the value with exactly `k` smaller input values.
- Invalid shape, duplicate values, or values outside the domain return `-1`.
- The 25-element cap keeps the source's median-of-medians pivot selection in its base branch, where it takes the lower median of at most five group medians.

The returned value is nonnegative, so `-1` is reserved for invalid input. Valid inputs take O(n²) worst-case time in this small bounded port contract and O(n) auxiliary space.

## Workload and source

[`workload.json`](workload.json) includes the pinned examples, lower/upper and middle ranks, group-of-five boundaries, the 25-element limit, and malformed inputs. The independent sorted-order oracle is [`median_search_oracle.py`](../../median_search_oracle.py).

- [TheAlgorithms/C-Plus-Plus `search/median_search.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/search/median_search.cpp)
- [TheAlgorithms/C-Plus-Plus-1 `search/median_search.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/search/median_search.cpp)

Both pinned copies have the same `median_of_medians` implementation and require distinct values. Their group-of-five pivot construction is retained for the bounded domain.

## Implementations

| Language | Port |
| --- | --- |
| C | [`c/m/median_search.c`](../../../c/m/median_search.c) |
| C3 | [`c3/m/median_search.c3`](../../../c3/m/median_search.c3) |
| C++ | [`cpp/m/median_search.cpp`](../../../cpp/m/median_search.cpp) |
| Elisa | [`elisa/m/median_search.elisa`](../../../elisa/m/median_search.elisa) |
| Nim | [`nim/m/median_search.nim`](../../../nim/m/median_search.nim) |
| Odin | [`odin/m/median_search.odin`](../../../odin/m/median_search.odin) |
| Rust | [`rust/m/median_search.rs`](../../../rust/m/median_search.rs) |
| V | [`v/m/median_search.v`](../../../v/m/median_search.v) |
| Zig | [`zig/m/median_search.zig`](../../../zig/m/median_search.zig) |
