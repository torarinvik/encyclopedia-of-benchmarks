# Odd-even sort

## Contract

Sort a mutable sequence of signed 64-bit integers in ascending order, in place. Equal values retain their relative order. Empty and single-element inputs are unchanged.

The C ABI entry point is:

```c
void odd_even_sort(int64_t *values, size_t length);
```

Each round compares adjacent pairs at even indices, then adjacent pairs at odd indices. Sorting ends when neither phase swaps a pair.

## Workload

[`workload.json`](workload.json) defines a deterministic modular-affine input `values[index] = ((index * 48,271) mod 2,000,003) - 1,000,001` at lengths `0`, `16`, `256`, and `1,024`. The portable sort runner prepares input and its sorted reference outside timing, restores input before each sample, times one sort call, then checks every output value.

Use [`benchmarks/harness/sort_runner.c`](../../harness/sort_runner.c) and [`benchmarks/run_sort.py`](../../run_sort.py). Search-only result fields are null for these sort records.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/o/odd_even_sort.c`](../../../c/o/odd_even_sort.c) | Independent portable implementation; TheAlgorithms C reference below |
| C3 | [`c3/o/odd_even_sort.c3`](../../../c3/o/odd_even_sort.c3) | Local port |
| C++ | [`cpp/o/odd_even_sort.cpp`](../../../cpp/o/odd_even_sort.cpp) | Independent portable implementation; TheAlgorithms C++ reference below |
| Elisa | [`elisa/o/odd_even_sort.elisa`](../../../elisa/o/odd_even_sort.elisa) | Local port for the custom Elisa compiler |
| Nim | [`nim/o/odd_even_sort.nim`](../../../nim/o/odd_even_sort.nim) | Local port |
| Odin | [`odin/o/odd_even_sort.odin`](../../../odin/o/odd_even_sort.odin) | Local port |
| Rust | [`rust/o/odd_even_sort.rs`](../../../rust/o/odd_even_sort.rs) | Local port |
| V | [`v/o/odd_even_sort.v`](../../../v/o/odd_even_sort.v) | Local port |
| Zig | [`zig/o/odd_even_sort.zig`](../../../zig/o/odd_even_sort.zig) | Local port |

The inspected C and C++ sources use the same odd-even adjacent-pair phases, although they order the phases differently. The local contract fixes one order and retains the same stable result.

## TheAlgorithms references

- [C `odd_even_sort.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/sorting/odd_even_sort.c)
- [C++ `odd_even_sort.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/odd_even_sort.cpp)
