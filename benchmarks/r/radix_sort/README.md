# Radix sort

## Contract

Sort a mutable sequence of signed 64-bit integers in ascending order, in place. Stability is preserved. Empty and single-element inputs are unchanged.

The C ABI entry point is:

```c
void radix_sort(int64_t *values, int64_t *scratch, size_t length);
```

The implementations use stable least-significant-digit passes over eight bytes. Each signed integer maps to an unsigned sort key that flips the sign ordering without signed overflow. The caller-provided scratch array needs `length + 256` signed 64-bit slots: a 256-counter prefix and an output area. The sort runner allocates scratch before timing.

## Workload

[`workload.json`](workload.json) uses deterministic modular-affine signed inputs at lengths `0`, `16`, `256`, and `1,024`. The runner prepares a sorted reference outside timing, restores input before each sample, times one radix-sort call, and verifies the full output.

Build the runner with `-DBENCHMARK_WITH_SCRATCH -DBENCHMARK_SCRATCH_EXTRA=256`. Use [`benchmarks/harness/sort_runner.c`](../../harness/sort_runner.c) and [`benchmarks/run_sort.py`](../../run_sort.py). Search-only result fields remain null.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/r/radix_sort.c`](../../../c/r/radix_sort.c) | Independent portable implementation; TheAlgorithms C reference below |
| C3 | [`c3/r/radix_sort.c3`](../../../c3/r/radix_sort.c3) | Local port |
| C++ | [`cpp/r/radix_sort.cpp`](../../../cpp/r/radix_sort.cpp) | Independent portable implementation; TheAlgorithms C++ reference below |
| Elisa | [`elisa/r/radix_sort.elisa`](../../../elisa/r/radix_sort.elisa) | Local port for the custom Elisa compiler |
| Nim | [`nim/r/radix_sort.nim`](../../../nim/r/radix_sort.nim) | Local port |
| Odin | [`odin/r/radix_sort.odin`](../../../odin/r/radix_sort.odin) | Local port |
| Rust | [`rust/r/radix_sort.rs`](../../../rust/r/radix_sort.rs) | Local port |
| V | [`v/r/radix_sort.v`](../../../v/r/radix_sort.v) | Local port |
| Zig | [`zig/r/radix_sort.zig`](../../../zig/r/radix_sort.zig) | Local port |

The checked C example uses decimal digits on nonnegative integers, C++ uses a decimal-digit counting pass, and Rust sorts unsigned values with a radix based on the input length. The local contract standardizes a byte-wise stable pass sequence for the full signed 64-bit domain.

## TheAlgorithms references

- [C `radix_sort.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/sorting/radix_sort.c)
- [C++ `radix_sort.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/radix_sort.cpp)
- [Rust `radix_sort.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/sorting/radix_sort.rs)
