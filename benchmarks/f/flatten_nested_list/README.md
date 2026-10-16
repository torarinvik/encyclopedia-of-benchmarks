# Flatten nested list

## Contract

Flatten a nested list recursively, preserving the left-to-right order of all leaves. The workload encodes a list tree as a preorder token stream: `INT64_MIN` opens a list, `INT64_MIN + 1` closes it, and all other values are leaves. The stream must contain one balanced root list, have at most 16 levels and 255 tokens, and use leaf values in `[-1,000,000, 1,000,000]`.

The scalar result is the signed FNV-1a 64-bit hash of the flattened leaves, each represented as eight little-endian bytes. `-1` marks invalid streams. This representation captures leaf order and repeated values while keeping the ABI bounded.

The pinned Clojure file provides both a recursive `flatten-1` and a tail-recursive `flatten-2`. Both recursively splice collections and produce the same left-to-right leaf sequence. The package implements the shared sequence behavior; it does not benchmark Clojure collection allocation.

The C ABI entry point is:

```c
int64_t flatten_nested_list(const int64_t *values, size_t length);
```

## Workload

[`workload.json`](workload.json) includes nested, empty, flat, deeper, and malformed streams. The expected value comes from the source-derived [runtime oracle](../../flatten_nested_list_oracle.py). The benchmark uses the `i64_array_scalar` ABI and [`benchmarks/run_i64_array_scalar.py`](../../run_i64_array_scalar.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/f/flatten_nested_list.c`](../../../c/f/flatten_nested_list.c) |
| C3 | [`c3/f/flatten_nested_list.c3`](../../../c3/f/flatten_nested_list.c3) |
| C++ | [`cpp/f/flatten_nested_list.cpp`](../../../cpp/f/flatten_nested_list.cpp) |
| Elisa | [`elisa/f/flatten_nested_list.elisa`](../../../elisa/f/flatten_nested_list.elisa) |
| Nim | [`nim/f/flatten_nested_list.nim`](../../../nim/f/flatten_nested_list.nim) |
| Odin | [`odin/f/flatten_nested_list.odin`](../../../odin/f/flatten_nested_list.odin) |
| Rust | [`rust/f/flatten_nested_list.rs`](../../../rust/f/flatten_nested_list.rs) |
| V | [`v/f/flatten_nested_list.v`](../../../v/f/flatten_nested_list.v) |
| Zig | [`zig/f/flatten_nested_list.zig`](../../../zig/f/flatten_nested_list.zig) |

## Pinned source

[Clojure `flatten_nested_list.clj`](https://github.com/TheAlgorithms/Clojure/blob/a9c5bec14928cb22fd4d69e951edf5bd15e16a18/src/data_structures/lists/flatten_nested_list.clj)
