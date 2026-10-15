# Unbounded knapsack

Find the maximum value that fits in a capacity when any item can be reused without limit.

## Contract

- The `i64_array_scalar` input is `[item_count, capacity, values[item_count], weights[item_count]]`.
- Item count is 0..16; capacity is 0..100; each item value and weight is 1..100. Packed length must be exactly `2 + 2*item_count`.
- For a nonempty item list, the source recurrence compares taking the current item again (when its weight fits) with skipping to the previous item. The base case fills the capacity with as many copies of item zero as fit. An empty list returns 0.
- Return the maximum obtainable value (at most 10,000 under these bounds), or -1 for invalid packed input.

## Source semantics

This package follows the pinned C++ source's unlimited-reuse recurrence. Its filename, `unbounded_0_1_knapsack.cpp`, is misleading: the source documentation and recurrence allow taking an item multiple times. Positive item values and weights are source preconditions.

## Workload

[`workload.json`](workload.json) covers repeated use of an item, no item fitting, an empty item list, mixed item weights, zero capacity, and invalid item data. The source-backed expected-value check is in [`benchmarks/run_i64_array_scalar.py`](../../run_i64_array_scalar.py).

## Pinned source

- [C++ `unbounded_0_1_knapsack.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/dynamic_programming/unbounded_0_1_knapsack.cpp)

## Ports

| Language | Source |
| --- | --- |
| C | [`c/u/unbounded_knapsack.c`](../../../c/u/unbounded_knapsack.c) |
| C3 | [`c3/u/unbounded_knapsack.c3`](../../../c3/u/unbounded_knapsack.c3) |
| C++ | [`cpp/u/unbounded_knapsack.cpp`](../../../cpp/u/unbounded_knapsack.cpp) |
| Elisa | [`elisa/u/unbounded_knapsack.elisa`](../../../elisa/u/unbounded_knapsack.elisa) |
| Nim | [`nim/u/unbounded_knapsack.nim`](../../../nim/u/unbounded_knapsack.nim) |
| Odin | [`odin/u/unbounded_knapsack.odin`](../../../odin/u/unbounded_knapsack.odin) |
| Rust | [`rust/u/unbounded_knapsack.rs`](../../../rust/u/unbounded_knapsack.rs) |
| V | [`v/u/unbounded_knapsack.v`](../../../v/u/unbounded_knapsack.v) |
| Zig | [`zig/u/unbounded_knapsack.zig`](../../../zig/u/unbounded_knapsack.zig) |
