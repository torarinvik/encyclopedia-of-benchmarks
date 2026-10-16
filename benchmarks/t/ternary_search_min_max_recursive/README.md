# Recursive ternary min/max search

## Contract

Use the pinned recursive ternary search to find the value of one known unimodal function. Packed input is `[mode, start_milli, end_milli, precision_milli]`. Mode 0 selects the source minimum function `f(x)=x*x-2*x+3`, whose center is 1; mode 1 selects the source maximum function `f(x)=-x*x-2*x+3`, whose center is -1. Endpoints are divided by 1000 and converted to binary32. Require `-100 <= start < center < end <= 100` and precision from 0.001 through 0.008.

The recursive interval updates and comparisons match the pinned Rust source. Recursion stops when `abs(end-start) < precision`, and the result is `f(start)` as returned by the source. The bounded width (at most 200) and minimum precision (0.001) require at most 31 interval reductions followed by the base call at depth 32. The binary32 result is promoted to binary64 for the scalar ABI. Workload absolute tolerance is 1e-4. Invalid input returns `-1e300`.

This package measures continuous unimodal optimization. The existing `ternary_search` package searches a sorted integer sequence and has a different contract.

## Workload

Cases and expected results are in [`workload.json`](workload.json). The package uses the `i64_array_float64` ABI with a binary64 scalar result.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/t/ternary_search_min_max_recursive.c`](../../../c/t/ternary_search_min_max_recursive.c) |
| C3 | [`c3/t/ternary_search_min_max_recursive.c3`](../../../c3/t/ternary_search_min_max_recursive.c3) |
| C++ | [`cpp/t/ternary_search_min_max_recursive.cpp`](../../../cpp/t/ternary_search_min_max_recursive.cpp) |
| Elisa | [`elisa/t/ternary_search_min_max_recursive.elisa`](../../../elisa/t/ternary_search_min_max_recursive.elisa) |
| Nim | [`nim/t/ternary_search_min_max_recursive.nim`](../../../nim/t/ternary_search_min_max_recursive.nim) |
| Odin | [`odin/t/ternary_search_min_max_recursive.odin`](../../../odin/t/ternary_search_min_max_recursive.odin) |
| Rust | [`rust/t/ternary_search_min_max_recursive.rs`](../../../rust/t/ternary_search_min_max_recursive.rs) |
| V | [`v/t/ternary_search_min_max_recursive.v`](../../../v/t/ternary_search_min_max_recursive.v) |
| Zig | [`zig/t/ternary_search_min_max_recursive.zig`](../../../zig/t/ternary_search_min_max_recursive.zig) |

## TheAlgorithms reference

- [Rust `ternary_search_min_max_recursive.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/searching/ternary_search_min_max_recursive.rs)
