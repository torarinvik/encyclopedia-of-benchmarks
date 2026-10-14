# Quick Sort

## Contract

Sort a mutable sequence of signed 64-bit integers in ascending order, in place. Empty and single-element inputs are unchanged. Use the final value in each active half-open range as a Lomuto pivot. Values less than or equal to it go left; larger values go right. The implementation recurses into the smaller partition and iterates over the larger one to bound call-stack depth. Stability is not promised.

The C ABI entry point is:

```c
void quick_sort(int64_t *values, size_t length);
```

## Workload

[`workload.json`](workload.json) uses a deterministic modular-affine input `values[index] = ((index * 48,271) mod 2,000,003) - 1,000,001` at lengths `0`, `16`, `256`, and `1,024`. The shared sort runner builds a sorted reference outside timing, restores input before each timed call, and checks the full result afterward.

Use [`benchmarks/harness/sort_runner.c`](../../harness/sort_runner.c) and [`benchmarks/run_sort.py`](../../run_sort.py). Sort result records set search-only target and comparison fields to null.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/q/quick_sort.c`](../../../c/q/quick_sort.c) | Independent portable implementation; TheAlgorithms C reference below |
| C3 | [`c3/q/quick_sort.c3`](../../../c3/q/quick_sort.c3) | Local port |
| C++ | [`cpp/q/quick_sort.cpp`](../../../cpp/q/quick_sort.cpp) | Independent portable implementation; TheAlgorithms C++ reference below |
| Elisa | [`elisa/q/quick_sort.elisa`](../../../elisa/q/quick_sort.elisa) | Local port for the custom Elisa compiler |
| Nim | [`nim/q/quick_sort.nim`](../../../nim/q/quick_sort.nim) | Local port |
| Odin | [`odin/q/quick_sort.odin`](../../../odin/q/quick_sort.odin) | Local port |
| Rust | [`rust/q/quick_sort.rs`](../../../rust/q/quick_sort.rs) | Local port |
| V | [`v/q/quick_sort.v`](../../../v/q/quick_sort.v) | Local port |
| Zig | [`zig/q/quick_sort.zig`](../../../zig/q/quick_sort.zig) | Local port |

The inspected C and C++ implementations use the last value as a Lomuto pivot but expose different inclusive-range and container APIs. The local ports use half-open ranges and recurse into the smaller side to bound stack depth.

## TheAlgorithms references

- [C `quick_sort.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/sorting/quick_sort.c)
- [C++ `quick_sort.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/quick_sort.cpp)
