# Stooge sort

## Contract

Sort a mutable sequence of signed 64-bit integers in ascending order, in place. Empty and single-element inputs are unchanged. Stability is not promised.

The C ABI entry point is:

```c
void stooge_sort(int64_t *values, size_t length);
```

For each active range, compare and possibly swap its endpoints, then recursively sort the first two thirds, the last two thirds, and the first two thirds again. This has approximately `O(n^2.71)` time complexity, so the workload uses small input sizes.

## Workload

[`workload.json`](workload.json) uses a deterministic modular-affine input at lengths `0`, `2`, `4`, `8`, and `16`. The shared sort runner prepares the reference outside timing, restores input before each sample, times one call, and checks the full result afterward.

Use [`benchmarks/harness/sort_runner.c`](../../harness/sort_runner.c) and [`benchmarks/run_sort.py`](../../run_sort.py). Sort result records set search-only target and comparison fields to null.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/s/stooge_sort.c`](../../../c/s/stooge_sort.c) | Independent portable implementation; TheAlgorithms C reference below |
| C3 | [`c3/s/stooge_sort.c3`](../../../c3/s/stooge_sort.c3) | Local port |
| C++ | [`cpp/s/stooge_sort.cpp`](../../../cpp/s/stooge_sort.cpp) | Independent portable implementation; TheAlgorithms C++ reference below |
| Elisa | [`elisa/s/stooge_sort.elisa`](../../../elisa/s/stooge_sort.elisa) | Local port for the custom Elisa compiler |
| Nim | [`nim/s/stooge_sort.nim`](../../../nim/s/stooge_sort.nim) | Local port |
| Odin | [`odin/s/stooge_sort.odin`](../../../odin/s/stooge_sort.odin) | Local port |
| Rust | [`rust/s/stooge_sort.rs`](../../../rust/s/stooge_sort.rs) | Local port |
| V | [`v/s/stooge_sort.v`](../../../v/s/stooge_sort.v) | Local port |
| Zig | [`zig/s/stooge_sort.zig`](../../../zig/s/stooge_sort.zig) | Local port |

The checked C, C++, and Rust implementations perform the same endpoint comparison and three recursive subrange passes. Their range conventions and empty-input guards differ. The local ports use half-open ranges, signed 64-bit values, and one in-place C ABI contract.

## TheAlgorithms references

- [C `stooge_sort.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/sorting/stooge_sort.c)
- [C++ `stooge_sort.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/stooge_sort.cpp)
- [Rust `stooge_sort.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/sorting/stooge_sort.rs)
