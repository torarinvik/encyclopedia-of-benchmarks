# Count Inversions

This benchmark counts strict inversions in a signed 64-bit integer sequence using merge sort. A pair of positions `(i, j)` is an inversion when `i < j` and `values[i] > values[j]`; equal values are not inversions.

## Contract

- The input is a read-only array of signed 64-bit integers.
- Empty and singleton inputs return `0`.
- Inputs of up to 4,096 values return the exact inversion count. The maximum possible count is `4,096 * 4,095 / 2 = 8,386,560`.
- Inputs longer than 4,096 values return `-1`.
- The implementation uses bottom-up merge sort in `O(n log n)` time and `O(n)` temporary storage.

## Upstream source

The primary source is [TheAlgorithms/C-Plus-Plus `sorting/count_inversions.cpp`](https://raw.githubusercontent.com/TheAlgorithms/C-Plus-Plus/master/sorting/count_inversions.cpp). Its templated merge sort counts `mid - i + 1` when a right-side value is strictly smaller than the current left-side value, and the public routine returns an unsigned 32-bit count. It also sorts the supplied array in place. This benchmark uses the repository's read-only `i64_array_scalar` ABI, so the ports merge into private buffers and return the same count without changing the caller's array. The 4,096-element cap keeps every possible result safely within the source's `uint32_t` range.

## Implementations and workload

All nine language ports use the same merge rule and length bound: `c/`, `c3/`, `cpp/`, `elisa/`, `nim/`, `odin/`, `rust/`, `v/`, and `zig/`. [`workload.json`](workload.json) covers empty and singleton sequences, already sorted and descending data, duplicate values, signed boundaries, upstream integer examples, the maximum supported length, and the first rejected length.

Build and record these ports with the `i64_array_scalar` ABI family and `benchmarks/run_i64_array_scalar.py`.
