# Monotonic array

## Contract

Return `1` when an integer array is entirely nondecreasing or entirely nonincreasing, allowing equal adjacent values; otherwise return `0`. Empty and singleton arrays return `1`, matching Python's vacuous `all()` behavior. Inputs are signed integers in `[-1,000,000,000, 1,000,000,000]` and contain at most 256 values. Invalid inputs return `-1`.

The C ABI entry point is:

```c
int64_t monotonic_array(const int64_t *values, size_t length);
```

## Workload

[`workload.json`](workload.json) covers empty, singleton, equal, ascending, descending, and direction-changing arrays. Expected results come from the source-derived [runtime oracle](../../monotonic_array_oracle.py). The benchmark uses the `i64_array_scalar` ABI family and [`benchmarks/run_i64_array_scalar.py`](../../run_i64_array_scalar.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/m/monotonic_array.c`](../../../c/m/monotonic_array.c) |
| C3 | [`c3/m/monotonic_array.c3`](../../../c3/m/monotonic_array.c3) |
| C++ | [`cpp/m/monotonic_array.cpp`](../../../cpp/m/monotonic_array.cpp) |
| Elisa | [`elisa/m/monotonic_array.elisa`](../../../elisa/m/monotonic_array.elisa) |
| Nim | [`nim/m/monotonic_array.nim`](../../../nim/m/monotonic_array.nim) |
| Odin | [`odin/m/monotonic_array.odin`](../../../odin/m/monotonic_array.odin) |
| Rust | [`rust/m/monotonic_array.rs`](../../../rust/m/monotonic_array.rs) |
| V | [`v/m/monotonic_array.v`](../../../v/m/monotonic_array.v) |
| Zig | [`zig/m/monotonic_array.zig`](../../../zig/m/monotonic_array.zig) |

## Pinned source

[Python `monotonic_array.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/arrays/monotonic_array.py)
