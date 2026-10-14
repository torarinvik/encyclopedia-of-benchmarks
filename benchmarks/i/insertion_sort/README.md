# Insertion sort

## Contract

Sort a mutable sequence of signed 64-bit integers in ascending order, in place. Equal values retain their relative order. Empty and single-element inputs are unchanged.

The C ABI entry point is:

```c
void insertion_sort(int64_t *values, size_t length);
```

The algorithm builds a sorted prefix by shifting larger values to the right and inserting the next key. The implementation uses portable scalar integer operations.

## Workload

[`workload.json`](workload.json) defines a deterministic modular-affine input `values[index] = ((index * 48,271) mod 2,000,003) - 1,000,001` for lengths `0`, `16`, `256`, and `1,024`. The sort runner prepares input and its `qsort` reference outside timed samples, restores the same input before each sample, and verifies the complete output after each call.

Use [`benchmarks/harness/sort_runner.c`](../../harness/sort_runner.c) and [`benchmarks/run_sort.py`](../../run_sort.py). Each sample times one in-place sort call.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/i/insertion_sort.c`](../../../c/i/insertion_sort.c) | Independent portable implementation; TheAlgorithms C reference below |
| C3 | [`c3/i/insertion_sort.c3`](../../../c3/i/insertion_sort.c3) | Local port |
| C++ | [`cpp/i/insertion_sort.cpp`](../../../cpp/i/insertion_sort.cpp) | Independent portable implementation; TheAlgorithms C++ reference below |
| Elisa | [`elisa/i/insertion_sort.elisa`](../../../elisa/i/insertion_sort.elisa) | Local port for the custom Elisa compiler |
| Nim | [`nim/i/insertion_sort.nim`](../../../nim/i/insertion_sort.nim) | Local port |
| Odin | [`odin/i/insertion_sort.odin`](../../../odin/i/insertion_sort.odin) | Local port |
| Rust | [`rust/i/insertion_sort.rs`](../../../rust/i/insertion_sort.rs) | Local port |
| V | [`v/i/insertion_sort.v`](../../../v/i/insertion_sort.v) | Local port |
| Zig | [`zig/i/insertion_sort.zig`](../../../zig/i/insertion_sort.zig) | Local port |

The checked C and C++ references both shift larger prefix elements before placing each key. The local contract fixes the type and result behavior for cross-language comparison.

## TheAlgorithms references

- [C `insertion_sort.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/sorting/insertion_sort.c)
- [C++ `insertion_sort.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/insertion_sort.cpp)
