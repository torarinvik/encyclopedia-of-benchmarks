# Bucket sort

## Contract

Sort a mutable sequence of signed 64-bit integers in ascending order, in place. Stability is preserved. Empty and single-element inputs are unchanged.

The C ABI entry point is:

```c
void bucket_sort(int64_t *values, int64_t *scratch, size_t length);
```

Values are mapped to monotonically ordered unsigned keys by flipping the signed order, then distributed stably into 256 buckets using the most significant byte. Each bucket is insertion-sorted, then copied back. The caller-provided scratch array needs `length + 256` signed 64-bit slots: 256 counters and an output area. The sort runner allocates scratch before timing. Bucket insertion sort gives an average cost of `O(n + 256 + sum(bucket_size^2))`; skewed inputs can make the local bucket sorts quadratic.

## Workload

[`workload.json`](workload.json) uses deterministic modular-affine values spanning a broad signed range, at lengths `0`, `16`, `256`, and `1,024`. The runner prepares a sorted reference outside timing, restores input before each sample, times one bucket-sort call, and verifies the full output.

Build the runner with `-DBENCHMARK_WITH_SCRATCH -DBENCHMARK_SCRATCH_EXTRA=256`. Use [`benchmarks/harness/sort_runner.c`](../../harness/sort_runner.c) and [`benchmarks/run_sort.py`](../../run_sort.py). Search-only result fields remain null.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/b/bucket_sort.c`](../../../c/b/bucket_sort.c) | Independent portable implementation; TheAlgorithms C reference below |
| C3 | [`c3/b/bucket_sort.c3`](../../../c3/b/bucket_sort.c3) | Local port |
| C++ | [`cpp/b/bucket_sort.cpp`](../../../cpp/b/bucket_sort.cpp) | Independent portable implementation; TheAlgorithms C++ reference below |
| Elisa | [`elisa/b/bucket_sort.elisa`](../../../elisa/b/bucket_sort.elisa) | Local port for the custom Elisa compiler |
| Nim | [`nim/b/bucket_sort.nim`](../../../nim/b/bucket_sort.nim) | Local port |
| Odin | [`odin/b/bucket_sort.odin`](../../../odin/b/bucket_sort.odin) | Local port |
| Rust | [`rust/b/bucket_sort.rs`](../../../rust/b/bucket_sort.rs) | Independent portable implementation; TheAlgorithms Rust reference below |
| V | [`v/b/bucket_sort.v`](../../../v/b/bucket_sort.v) | Local port |
| Zig | [`zig/b/bucket_sort.zig`](../../../zig/b/bucket_sort.zig) | Local port |

The checked C source uses five fixed-width linked-list buckets, C++ uses one vector per input value for normalized floats, and Rust uses `len + 1` buckets for nonnegative `usize` values. Their input domains, allocation strategies, and APIs differ. The local contract instead uses fixed-width top-byte buckets to cover every signed 64-bit key while keeping allocation outside the timed call.

## TheAlgorithms references

The candidate appears in 10 source repositories. These local source implementations were checked at the pinned commits in the catalog:

- [C `bucket_sort.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/sorting/bucket_sort.c)
- [C++ `bucket_sort.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/bucket_sort.cpp)
- [Rust `bucket_sort.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/sorting/bucket_sort.rs)
