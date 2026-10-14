# Selection sort

## Contract

Sort a mutable sequence of signed 64-bit integers in ascending order, in place. Stability is not promised. Empty and single-element inputs are unchanged.

The C ABI entry point is:

```c
void selection_sort(int64_t *values, size_t length);
```

For each output position, the algorithm finds the minimum element in the remaining suffix and swaps it into place. The implementation uses portable scalar integer operations.

## Workload

[`workload.json`](workload.json) defines a deterministic modular-affine input `values[index] = ((index * 48,271) mod 2,000,003) - 1,000,001` for lengths `0`, `16`, `256`, and `1,024`. The runner creates the input and its reference output before timing, restores the input for every sample, and checks the full sorted sequence afterward.

Use [`benchmarks/harness/sort_runner.c`](../../harness/sort_runner.c) and [`benchmarks/run_sort.py`](../../run_sort.py). Each sample times one sort call.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/s/selection_sort.c`](../../../c/s/selection_sort.c) | Independent portable implementation; TheAlgorithms C reference below |
| C3 | [`c3/s/selection_sort.c3`](../../../c3/s/selection_sort.c3) | Local port |
| C++ | [`cpp/s/selection_sort.cpp`](../../../cpp/s/selection_sort.cpp) | Local port |
| Elisa | [`elisa/s/selection_sort.elisa`](../../../elisa/s/selection_sort.elisa) | Local port for the custom Elisa compiler |
| Nim | [`nim/s/selection_sort.nim`](../../../nim/s/selection_sort.nim) | Local port |
| Odin | [`odin/s/selection_sort.odin`](../../../odin/s/selection_sort.odin) | Local port |
| Rust | [`rust/s/selection_sort.rs`](../../../rust/s/selection_sort.rs) | Local port |
| V | [`v/s/selection_sort.v`](../../../v/s/selection_sort.v) | Local port |
| Zig | [`zig/s/selection_sort.zig`](../../../zig/s/selection_sort.zig) | Local port |

The checked upstream C implementation selects the minimum value from each suffix. The local versions share that behavior and the same signed 64-bit in-place contract.

## TheAlgorithms reference

- [C `selection_sort.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/sorting/selection_sort.c)
