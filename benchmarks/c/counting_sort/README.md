# Counting sort

## Contract

Sort a mutable sequence of signed 64-bit integers in ascending order, in place. Every key must be in the inclusive range `[-128, 128]`. Empty and single-element inputs are unchanged.

The C ABI entry point is:

```c
void counting_sort(int64_t *values, int64_t *counts, size_t length);
```

The caller-provided scratch array must hold at least 257 signed 64-bit counters. The implementation clears the histogram, counts each key at offset `value + 128`, then writes values back in ascending bucket order. The shared sort runner allocates this extra scratch capacity outside the timed call.

## Workload

[`workload.json`](workload.json) generates duplicate keys in the supported range using `(index * 73) mod 257 - 128` at lengths `0`, `16`, `256`, and `1,024`. The runner prepares its sorted reference outside timing, restores input before each sample, times one counting-sort call, and validates the complete output.

Build the runner with `-DBENCHMARK_WITH_SCRATCH -DBENCHMARK_SCRATCH_EXTRA=257`. Use [`benchmarks/harness/sort_runner.c`](../../harness/sort_runner.c) and [`benchmarks/run_sort.py`](../../run_sort.py). Sort result records leave search-specific fields null.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/c/counting_sort.c`](../../../c/c/counting_sort.c) | Independent portable implementation; TheAlgorithms C reference below |
| C3 | [`c3/c/counting_sort.c3`](../../../c3/c/counting_sort.c3) | Local port |
| C++ | [`cpp/c/counting_sort.cpp`](../../../cpp/c/counting_sort.cpp) | Independent portable implementation; TheAlgorithms C++ reference below |
| Elisa | [`elisa/c/counting_sort.elisa`](../../../elisa/c/counting_sort.elisa) | Local port for the custom Elisa compiler |
| Nim | [`nim/c/counting_sort.nim`](../../../nim/c/counting_sort.nim) | Local port |
| Odin | [`odin/c/counting_sort.odin`](../../../odin/c/counting_sort.odin) | Local port |
| Rust | [`rust/c/counting_sort.rs`](../../../rust/c/counting_sort.rs) | Local port |
| V | [`v/c/counting_sort.v`](../../../v/c/counting_sort.v) | Local port |
| Zig | [`zig/c/counting_sort.zig`](../../../zig/c/counting_sort.zig) | Local port |

The C source counts nonnegative keys and prints them; C++ finds the input minimum and maximum, builds a dynamic histogram, and returns a new array; Rust provides an in-place unsigned-key implementation with a maximum value. The local contract fixes a small signed key range so all nine ports share the same bounded histogram and workload.

The `pigeonhole_sort` name uses the same frequency-array reconstruction on this integer-only contract. Its source candidates, including the C, C++, and Rust implementations, are cataloged as aliases here rather than as a second benchmark.

## TheAlgorithms references

- [C `counting_sort.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/sorting/counting_sort.c)
- [C++ `counting_sort.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/counting_sort.cpp)
- [Rust `counting_sort.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/sorting/counting_sort.rs)
- [C `pigeonhole_sort.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/sorting/pigeonhole_sort.c), [C++ `pigeonhole_sort.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/pigeonhole_sort.cpp), and [Rust `pigeonhole_sort.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/sorting/pigeonhole_sort.rs)
