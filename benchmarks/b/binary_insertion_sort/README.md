# Binary insertion sort

## Contract

Sort a mutable sequence of signed 64-bit integers in ascending order, in place. Equal values retain their relative order. Empty and single-element inputs are unchanged.

The C ABI entry point is:

```c
void binary_insertion_sort(int64_t *values, size_t length);
```

For each item after the first, a binary upper-bound search finds the position after any equal values in the sorted prefix. Larger values shift right to make room. This reduces comparisons to logarithmic per insertion while preserving insertion sort's quadratic worst-case movement.

## Workload

[`workload.json`](workload.json) uses the shared deterministic modular-affine inputs at lengths `0`, `16`, `256`, and `1,024`. The sort runner prepares a sorted reference outside timing, restores the input before each sample, times one in-place call, and checks the full output afterward.

Use [`benchmarks/harness/sort_runner.c`](../../harness/sort_runner.c) and [`benchmarks/run_sort.py`](../../run_sort.py). Sort result records set search-only fields to null.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/b/binary_insertion_sort.c`](../../../c/b/binary_insertion_sort.c) | Independent portable implementation; TheAlgorithms C reference below |
| C3 | [`c3/b/binary_insertion_sort.c3`](../../../c3/b/binary_insertion_sort.c3) | Local port |
| C++ | [`cpp/b/binary_insertion_sort.cpp`](../../../cpp/b/binary_insertion_sort.cpp) | Independent portable implementation; TheAlgorithms C++ reference below |
| Elisa | [`elisa/b/binary_insertion_sort.elisa`](../../../elisa/b/binary_insertion_sort.elisa) | Local port for the custom Elisa compiler |
| Nim | [`nim/b/binary_insertion_sort.nim`](../../../nim/b/binary_insertion_sort.nim) | Local port |
| Odin | [`odin/b/binary_insertion_sort.odin`](../../../odin/b/binary_insertion_sort.odin) | Local port |
| Rust | [`rust/b/binary_insertion_sort.rs`](../../../rust/b/binary_insertion_sort.rs) | Local port |
| V | [`v/b/binary_insertion_sort.v`](../../../v/b/binary_insertion_sort.v) | Local port |
| Zig | [`zig/b/binary_insertion_sort.zig`](../../../zig/b/binary_insertion_sort.zig) | Local port |

The C and C++ references search for an insertion point in the sorted prefix, then shift the suffix. Their recursive search boundary details differ, and the C midpoint expression does not consistently calculate from the lower bound. Rust uses a lower-bound helper and slice rotation. The local ports use an upper-bound search so duplicates remain stable, with a shared signed 64-bit contract.

## TheAlgorithms references

- [C `binary_insertion_sort.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/sorting/binary_insertion_sort.c)
- [C++ `binary_insertion_sort.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/binary_insertion_sort.cpp)
- [Rust `binary_insertion_sort.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/sorting/binary_insertion_sort.rs)
