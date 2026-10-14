# Bitonic sort

## Contract

Sort a mutable sequence of signed 64-bit integers in ascending order, in place. The length must be zero, one, or a power of two. Empty and single-element inputs are unchanged.

The C ABI entry point is:

```c
void bitonic_sort(int64_t *values, size_t length);
```

The implementation recursively creates bitonic sequences, then merges them with compare-and-swap stages. It uses no auxiliary storage and runs in `O(n log² n)` time. Power-of-two length is required by this network; the workload uses `0`, `1`, `16`, `256`, and `1,024` elements.

## Workload

[`workload.json`](workload.json) uses deterministic modular-affine signed inputs at the supported lengths. The runner prepares a sorted reference outside timing, restores input before each sample, times one bitonic-sort call, and verifies the complete output.

Use [`benchmarks/harness/sort_runner.c`](../../harness/sort_runner.c) and [`benchmarks/run_sort.py`](../../run_sort.py). Search-only result fields remain null.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/b/bitonic_sort.c`](../../../c/b/bitonic_sort.c) | Local port |
| C3 | [`c3/b/bitonic_sort.c3`](../../../c3/b/bitonic_sort.c3) | Local port |
| C++ | [`cpp/b/bitonic_sort.cpp`](../../../cpp/b/bitonic_sort.cpp) | Independent portable implementation; TheAlgorithms C++ reference below |
| Elisa | [`elisa/b/bitonic_sort.elisa`](../../../elisa/b/bitonic_sort.elisa) | Local port for the custom Elisa compiler |
| Nim | [`nim/b/bitonic_sort.nim`](../../../nim/b/bitonic_sort.nim) | Local port |
| Odin | [`odin/b/bitonic_sort.odin`](../../../odin/b/bitonic_sort.odin) | Local port |
| Rust | [`rust/b/bitonic_sort.rs`](../../../rust/b/bitonic_sort.rs) | Independent portable implementation; TheAlgorithms Rust reference below |
| V | [`v/b/bitonic_sort.v`](../../../v/b/bitonic_sort.v) | Local port |
| Zig | [`zig/b/bitonic_sort.zig`](../../../zig/b/bitonic_sort.zig) | Local port |

The checked C++ and Rust sources both document the power-of-two length constraint and use recursive compare-and-swap merges. The local ports apply the same constraint to every language and expose the same ascending in-place contract.

## TheAlgorithms references

The candidate appears in six source repositories and directly in C++ and Rust among the local source folders:

- [C++ `bitonic_sort.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/bitonic_sort.cpp)
- [Rust `bitonic_sort.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74a939ec5163648458a8c2b46fd4c/src/sorting/bitonic_sort.rs)
