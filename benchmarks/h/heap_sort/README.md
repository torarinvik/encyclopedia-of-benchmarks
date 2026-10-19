# Heap Sort

## Contract

Sort a mutable sequence of signed 64-bit integers in ascending order, in place. Empty and single-element inputs are unchanged. Build a zero-based max heap, then repeatedly move its root to the end of the active prefix and sift the replacement root down. Stability is not promised.

The C ABI entry point is:

```c
void heap_sort(int64_t *values, size_t length);
```

## ANSIbench relation

ANSIbench's NBench numeric-sort kernel is `NumHeapSort`/`NumSift` in [`nbench/src/nbench1.c`](https://github.com/nfinit/ansibench/blob/ef90abd09d7b7bb1f2809f896d6f67fb9724bebe/nbench/src/nbench1.c). This package covers its in-place integer heapsort core. It uses a fixed modular-affine input and does not reproduce NBench's random array generation, repeated batches, self-adjustment, or score calculation.

## Workload

[`workload.json`](workload.json) uses a deterministic modular-affine input `values[index] = ((index * 48,271) mod 2,000,003) - 1,000,001` at lengths `0`, `16`, `256`, and `1,024`. The shared sort runner builds a sorted reference outside timing, restores input before each timed call, and checks the full result afterward.

Use [`benchmarks/harness/sort_runner.c`](../../harness/sort_runner.c) and [`benchmarks/run_sort.py`](../../run_sort.py). Run `python3 benchmarks/verify_heap_sort.py` to check all nine ports against exhaustive short arrays, signed 64-bit boundaries, seeded random arrays, and each published workload length. Sort result records set search-only target and comparison fields to null.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/h/heap_sort.c`](../../../c/h/heap_sort.c) | Independent portable implementation; TheAlgorithms C reference below |
| C3 | [`c3/h/heap_sort.c3`](../../../c3/h/heap_sort.c3) | Local port |
| C++ | [`cpp/h/heap_sort.cpp`](../../../cpp/h/heap_sort.cpp) | Independent portable implementation; TheAlgorithms C++ reference below |
| Elisa | [`elisa/h/heap_sort.elisa`](../../../elisa/h/heap_sort.elisa) | Local port for the custom Elisa compiler |
| Nim | [`nim/h/heap_sort.nim`](../../../nim/h/heap_sort.nim) | Local port |
| Odin | [`odin/h/heap_sort.odin`](../../../odin/h/heap_sort.odin) | Local port |
| Rust | [`rust/h/heap_sort.rs`](../../../rust/h/heap_sort.rs) | Local port |
| V | [`v/h/heap_sort.v`](../../../v/h/heap_sort.v) | Local port |
| Zig | [`zig/h/heap_sort.zig`](../../../zig/h/heap_sort.zig) | Local port |

The checked C sample uses a one-based heap and an interactive fixed-size array; the C++ source builds and extracts from a zero-based max heap. The local ports use one zero-based signed 64-bit in-place contract.

## TheAlgorithms references

- [C `heap_sort.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/sorting/heap_sort.c)
- [C++ `heap_sort.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/heap_sort.cpp)
