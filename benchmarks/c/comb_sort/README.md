# Comb sort

## Contract

Sort a mutable sequence of signed 64-bit integers in ascending order, in place. Stability is not promised. Empty and single-element inputs are unchanged.

The C ABI entry point is:

```c
void comb_sort(int64_t *values, size_t length);
```

The local implementations shrink the gap by the rational factor `10/13`, compare elements at that gap, and swap any out-of-order pair. They finish only after a gap-one pass makes no swaps. Integer arithmetic avoids architecture-specific operations.

## Workload

[`workload.json`](workload.json) uses a deterministic modular-affine input `values[index] = ((index * 48,271) mod 2,000,003) - 1,000,001` at lengths `0`, `16`, `256`, and `1,024`. The shared sort runner prepares this input and a `qsort` reference outside timing, copies the input before each sample, times one sort call, and checks the full output afterward.

Use [`benchmarks/harness/sort_runner.c`](../../harness/sort_runner.c) and [`benchmarks/run_sort.py`](../../run_sort.py). Sort result records leave search-only target and comparison fields null.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/c/comb_sort.c`](../../../c/c/comb_sort.c) | Independent portable implementation; TheAlgorithms C reference below |
| C3 | [`c3/c/comb_sort.c3`](../../../c3/c/comb_sort.c3) | Local port |
| C++ | [`cpp/c/comb_sort.cpp`](../../../cpp/c/comb_sort.cpp) | Independent portable implementation; TheAlgorithms C++ reference below |
| Elisa | [`elisa/c/comb_sort.elisa`](../../../elisa/c/comb_sort.elisa) | Local port for the custom Elisa compiler |
| Nim | [`nim/c/comb_sort.nim`](../../../nim/c/comb_sort.nim) | Local port |
| Odin | [`odin/c/comb_sort.odin`](../../../odin/c/comb_sort.odin) | Local port |
| Rust | [`rust/c/comb_sort.rs`](../../../rust/c/comb_sort.rs) | Local port |
| V | [`v/c/comb_sort.v`](../../../v/c/comb_sort.v) | Local port |
| Zig | [`zig/c/comb_sort.zig`](../../../zig/c/comb_sort.zig) | Local port |

The checked C and C++ examples use a shrink factor near `1.3`; their helper APIs and gap termination differ. These local ports share the same shrinking rule and termination contract.

## TheAlgorithms references

- [C `comb_sort.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/sorting/comb_sort.c)
- [C++ `comb_sort.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/comb_sort.cpp)
