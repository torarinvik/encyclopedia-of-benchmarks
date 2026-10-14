# Shell sort

## Contract

Sort a mutable sequence of signed 64-bit integers in ascending order, in place. Stability is not promised. Empty and single-element inputs are unchanged.

The C ABI entry point is:

```c
void shell_sort(int64_t *values, size_t length);
```

The local implementations use Shell sort with a gap sequence that begins at half the input length and halves on every pass. They insertion-sort elements within each gap subsequence using portable integer index arithmetic.

## Workload

[`workload.json`](workload.json) defines a deterministic modular-affine input `values[index] = ((index * 48,271) mod 2,000,003) - 1,000,001` for lengths `0`, `16`, `256`, and `1,024`. The sort runner prepares the input and `qsort` reference outside timing, copies the same input before each sample, and verifies the complete sorted output after timing.

Use [`benchmarks/harness/sort_runner.c`](../../harness/sort_runner.c) and [`benchmarks/run_sort.py`](../../run_sort.py). Each sample times one sort call.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/s/shell_sort.c`](../../../c/s/shell_sort.c) | Independent portable implementation; TheAlgorithms C reference below |
| C3 | [`c3/s/shell_sort.c3`](../../../c3/s/shell_sort.c3) | Local port |
| C++ | [`cpp/s/shell_sort.cpp`](../../../cpp/s/shell_sort.cpp) | Local port |
| Elisa | [`elisa/s/shell_sort.elisa`](../../../elisa/s/shell_sort.elisa) | Local port for the custom Elisa compiler |
| Nim | [`nim/s/shell_sort.nim`](../../../nim/s/shell_sort.nim) | Local port |
| Odin | [`odin/s/shell_sort.odin`](../../../odin/s/shell_sort.odin) | Local port |
| Rust | [`rust/s/shell_sort.rs`](../../../rust/s/shell_sort.rs) | Local port |
| V | [`v/s/shell_sort.v`](../../../v/s/shell_sort.v) | Local port |
| Zig | [`zig/s/shell_sort.zig`](../../../zig/s/shell_sort.zig) | Local port |

The checked C reference uses a halving gap sequence. Its main program also includes timing and display code, which is outside this shared contract; these ports expose only the sorting operation.

## TheAlgorithms reference

- [C `shell_sort.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/sorting/shell_sort.c)
