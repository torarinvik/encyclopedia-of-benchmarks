# Merge sort

## Contract

Sort a mutable sequence of signed 64-bit integers in ascending order, in place. Equal values retain their relative order. Empty and single-element inputs are unchanged.

The C ABI entry point is:

```c
void merge_sort(int64_t *values, int64_t *scratch, size_t length);
```

The local implementations use stable bottom-up merging. The sort runner allocates one scratch array before timing and passes it to the algorithm; each merge pass copies its merged runs back to the input. Scratch allocation is excluded from the timed call, and the workload records this ABI explicitly.

## Workload

[`workload.json`](workload.json) uses the shared deterministic modular-affine input at lengths `0`, `16`, `256`, and `1,024`. The runner prepares a sorted reference outside timing, restores input before each sample, times one merge-sort call, and checks the full result afterward.

Build the runner with `-DBENCHMARK_WITH_SCRATCH`. Use [`benchmarks/harness/sort_runner.c`](../../harness/sort_runner.c) and [`benchmarks/run_sort.py`](../../run_sort.py). Sort result records set search-only target and comparison fields to null.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/m/merge_sort.c`](../../../c/m/merge_sort.c) | Independent portable implementation; TheAlgorithms C reference below |
| C3 | [`c3/m/merge_sort.c3`](../../../c3/m/merge_sort.c3) | Local port |
| C++ | [`cpp/m/merge_sort.cpp`](../../../cpp/m/merge_sort.cpp) | Independent portable implementation; TheAlgorithms C++ reference below |
| Elisa | [`elisa/m/merge_sort.elisa`](../../../elisa/m/merge_sort.elisa) | Local port for the custom Elisa compiler |
| Nim | [`nim/m/merge_sort.nim`](../../../nim/m/merge_sort.nim) | Local port |
| Odin | [`odin/m/merge_sort.odin`](../../../odin/m/merge_sort.odin) | Local port |
| Rust | [`rust/m/merge_sort.rs`](../../../rust/m/merge_sort.rs) | Local port |
| V | [`v/m/merge_sort.v`](../../../v/m/merge_sort.v) | Local port |
| Zig | [`zig/m/merge_sort.zig`](../../../zig/m/merge_sort.zig) | Local port |

The C version recursively merges inclusive ranges and allocates a temporary array per merge; C++ allocates two temporary vectors per merge. Rust provides both top-down and bottom-up variants that allocate temporary vectors. The local contract fixes a bottom-up variant and a reusable caller-owned scratch array for consistent allocation treatment across languages.

## TheAlgorithms references

- [C `merge_sort.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/sorting/merge_sort.c)
- [C++ `merge_sort.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/merge_sort.cpp)
- [Rust `merge_sort.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/sorting/merge_sort.rs)
