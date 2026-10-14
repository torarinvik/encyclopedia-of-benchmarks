# Strand sort

## Contract

Sort a mutable sequence of signed 64-bit integers in ascending order, in place. Stability is preserved. Empty and single-element inputs are unchanged.

The C ABI entry point is:

```c
void strand_sort(int64_t *values, int64_t *scratch, size_t length);
```

Each pass extracts a nondecreasing strand from the remaining prefix, compacts the unselected values in order, shifts the accumulated result to make room, and merges the new strand into that sorted result. The caller-provided scratch array needs `length` signed 64-bit slots and is allocated outside timing. Strand sort is `O(n)` on already sorted input and can take `O(n^2)` in the worst case.

## Workload

[`workload.json`](workload.json) uses deterministic modular-affine signed inputs at lengths `0`, `16`, `256`, and `1,024`. The runner prepares a sorted reference outside timing, restores input before each sample, times one strand-sort call, and verifies the complete output.

Build the runner with `-DBENCHMARK_WITH_SCRATCH`. Use [`benchmarks/harness/sort_runner.c`](../../harness/sort_runner.c) and [`benchmarks/run_sort.py`](../../run_sort.py). Search-only result fields remain null.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/s/strand_sort.c`](../../../c/s/strand_sort.c) | Local implementation |
| C3 | [`c3/s/strand_sort.c3`](../../../c3/s/strand_sort.c3) | Local port |
| C++ | [`cpp/s/strand_sort.cpp`](../../../cpp/s/strand_sort.cpp) | Independent portable implementation; TheAlgorithms C++ reference below |
| Elisa | [`elisa/s/strand_sort.elisa`](../../../elisa/s/strand_sort.elisa) | Local port for the custom Elisa compiler |
| Nim | [`nim/s/strand_sort.nim`](../../../nim/s/strand_sort.nim) | Local port |
| Odin | [`odin/s/strand_sort.odin`](../../../odin/s/strand_sort.odin) | Local port |
| Rust | [`rust/s/strand_sort.rs`](../../../rust/s/strand_sort.rs) | Independent portable implementation; TheAlgorithms Rust reference below |
| V | [`v/s/strand_sort.v`](../../../v/s/strand_sort.v) | Local port |
| Zig | [`zig/s/strand_sort.zig`](../../../zig/s/strand_sort.zig) | Local port |

The checked C++ implementation extracts increasing subsequences into lists and merges them with the accumulated result. Rust uses a vector-based strand and merge. Local ports use flat arrays and a reusable strand buffer while preserving the same extraction-and-merge strategy.

## TheAlgorithms references

The candidate appears in six source repositories and directly in C++ and Rust among the local source folders:

- [C++ `strand_sort.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/strand_sort.cpp)
- [Rust `strand_sort.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/sorting/strand_sort.rs)
