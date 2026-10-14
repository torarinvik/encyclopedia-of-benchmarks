# Cycle sort

## Contract

Sort a mutable sequence of signed 64-bit integers in ascending order, in place. Stability is not promised. Empty and single-element inputs are unchanged. Equal values are skipped while locating a cycle slot; every port uses bounds checks for those skips.

The C ABI entry point is:

```c
void cycle_sort(int64_t *values, size_t length);
```

For each cycle start, count smaller values to locate an item's rank, then rotate displaced values into their ranked positions. The algorithm aims to minimize writes and uses constant auxiliary storage.

## Workload

[`workload.json`](workload.json) uses the shared deterministic modular-affine inputs at lengths `0`, `16`, `256`, and `1,024`. The generated prefix uses distinct keys. The sort runner prepares a sorted reference outside timing, restores input before each sample, times one in-place call, and checks the full output afterward.

Use [`benchmarks/harness/sort_runner.c`](../../harness/sort_runner.c) and [`benchmarks/run_sort.py`](../../run_sort.py). Sort result records set search-only fields to null.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/c/cycle_sort.c`](../../../c/c/cycle_sort.c) | Independent portable implementation; TheAlgorithms C reference below |
| C3 | [`c3/c/cycle_sort.c3`](../../../c3/c/cycle_sort.c3) | Local port |
| C++ | [`cpp/c/cycle_sort.cpp`](../../../cpp/c/cycle_sort.cpp) | Independent portable implementation; TheAlgorithms C++ reference below |
| Elisa | [`elisa/c/cycle_sort.elisa`](../../../elisa/c/cycle_sort.elisa) | Local port for the custom Elisa compiler |
| Nim | [`nim/c/cycle_sort.nim`](../../../nim/c/cycle_sort.nim) | Local port |
| Odin | [`odin/c/cycle_sort.odin`](../../../odin/c/cycle_sort.odin) | Local port |
| Rust | [`rust/c/cycle_sort.rs`](../../../rust/c/cycle_sort.rs) | Local port |
| V | [`v/c/cycle_sort.v`](../../../v/c/cycle_sort.v) | Local port |
| Zig | [`zig/c/cycle_sort.zig`](../../../zig/c/cycle_sort.zig) | Local port |

The C source counts writes in an interactive demonstration. The C++ source returns a sorted vector copy, and the Rust source mutates a slice. The local contract uses a common in-place ABI and guards duplicate skips at the end of a range.

## TheAlgorithms references

- [C `cycle_sort.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/sorting/cycle_sort.c)
- [C++ `cycle_sort.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/cycle_sort.cpp)
- [Rust `cycle_sort.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/sorting/cycle_sort.rs)
