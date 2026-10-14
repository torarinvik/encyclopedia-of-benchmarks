# Bubble sort

## Contract

Sort a mutable sequence of signed 64-bit integers in ascending order, in place. Equal values retain their relative order. Empty and single-element inputs are unchanged.

The C ABI entry point is:

```c
void bubble_sort(int64_t *values, size_t length);
```

The implementation compares adjacent values, swaps out-of-order pairs, and stops early when a full pass makes no swaps. It uses portable scalar integer operations.

## Workload

[`workload.json`](workload.json) defines a deterministic modular-affine input `values[index] = ((index * 48,271) mod 2,000,003) - 1,000,001` for lengths `0`, `16`, `256`, and `1,024`. The sort runner creates the input and a `qsort` reference before timing. It restores the original sequence before each sample and checks the complete sorted output after timing.

Use [`benchmarks/harness/sort_runner.c`](../../harness/sort_runner.c) and [`benchmarks/run_sort.py`](../../run_sort.py); each timed sample contains one sort call. Sorting result records use a null target and comparison count because those fields do not apply to a sort.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/b/bubble_sort.c`](../../../c/b/bubble_sort.c) | Independent portable implementation; TheAlgorithms C reference below |
| C3 | [`c3/b/bubble_sort.c3`](../../../c3/b/bubble_sort.c3) | Local port |
| C++ | [`cpp/b/bubble_sort.cpp`](../../../cpp/b/bubble_sort.cpp) | Independent portable implementation; TheAlgorithms C++ reference below |
| Elisa | [`elisa/b/bubble_sort.elisa`](../../../elisa/b/bubble_sort.elisa) | Local port for the custom Elisa compiler |
| Nim | [`nim/b/bubble_sort.nim`](../../../nim/b/bubble_sort.nim) | Local port |
| Odin | [`odin/b/bubble_sort.odin`](../../../odin/b/bubble_sort.odin) | Local port |
| Rust | [`rust/b/bubble_sort.rs`](../../../rust/b/bubble_sort.rs) | Local port |
| V | [`v/b/bubble_sort.v`](../../../v/b/bubble_sort.v) | Local port |
| Zig | [`zig/b/bubble_sort.zig`](../../../zig/b/bubble_sort.zig) | Local port |

The checked upstream C implementation uses an early-exit flag; the C++ implementation has the same adjacent-swap and early-exit behavior. Their element types and APIs differ from the local signed 64-bit C ABI.

## TheAlgorithms references

- [C `bubble_sort.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/sorting/bubble_sort.c)
- [C++ `bubble_sort.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/bubble_sort.cpp)
