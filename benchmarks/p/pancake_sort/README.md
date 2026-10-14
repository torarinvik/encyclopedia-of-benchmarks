# Pancake sort

## Contract

Sort a mutable sequence of signed 64-bit integers in ascending order, in place. Stability is not promised. Empty and single-element inputs are unchanged.

The C ABI entry point is:

```c
void pancake_sort(int64_t *values, size_t length);
```

For each shrinking prefix, the algorithm finds its maximum and uses up to two prefix reversals to move that value to its final position.

## Workload

[`workload.json`](workload.json) defines a deterministic modular-affine input `values[index] = ((index * 48,271) mod 2,000,003) - 1,000,001` at lengths `0`, `16`, `256`, and `1,024`. The shared sort runner initializes input and a `qsort` reference outside timing, restores input before every sample, times one sort call, and checks the full output afterward.

Use [`benchmarks/harness/sort_runner.c`](../../harness/sort_runner.c) and [`benchmarks/run_sort.py`](../../run_sort.py). Sort result records set search-only fields to null.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/p/pancake_sort.c`](../../../c/p/pancake_sort.c) | Independent portable implementation; TheAlgorithms C reference below |
| C3 | [`c3/p/pancake_sort.c3`](../../../c3/p/pancake_sort.c3) | Local port |
| C++ | [`cpp/p/pancake_sort.cpp`](../../../cpp/p/pancake_sort.cpp) | Independent portable implementation; TheAlgorithms C++ reference below |
| Elisa | [`elisa/p/pancake_sort.elisa`](../../../elisa/p/pancake_sort.elisa) | Local port for the custom Elisa compiler |
| Nim | [`nim/p/pancake_sort.nim`](../../../nim/p/pancake_sort.nim) | Local port |
| Odin | [`odin/p/pancake_sort.odin`](../../../odin/p/pancake_sort.odin) | Local port |
| Rust | [`rust/p/pancake_sort.rs`](../../../rust/p/pancake_sort.rs) | Local port |
| V | [`v/p/pancake_sort.v`](../../../v/p/pancake_sort.v) | Local port |
| Zig | [`zig/p/pancake_sort.zig`](../../../zig/p/pancake_sort.zig) | Local port |

The inspected C and C++ references select a maximum from each active prefix and move it using flips or reversals. The local ports use the same algorithm with one explicit signed 64-bit in-place contract.

## TheAlgorithms references

- [C `pancake_sort.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/sorting/pancake_sort.c)
- [C++ `pancake_sort.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/pancake_sort.cpp)
