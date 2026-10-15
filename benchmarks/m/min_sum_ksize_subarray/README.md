# Minimum sum in a fixed-size window

This benchmark returns the minimum sum among all contiguous windows of a fixed length.

## Contract

- Input uses the `i64_array_scalar` ABI and packs `[n, k, value_0, ...]` in a signed 64-bit array.
- `n` is 0 through 100,000, `k` is 0 through 100,000, and the packed length must equal `n + 2`.
- Every value is in `[-10,000, 10,000]`. This bound keeps the Java source's 32-bit running sum and update arithmetic in range.
- When `k > n`, return the source result `-1`. When `k == 0`, return `0`; the Java loop subtracts and adds each same value, leaving every zero-length window sum at zero. Otherwise return the minimum sum among the `k`-element windows.
- Malformed packing or values outside the stated bounds return `INT64_MIN`. The valid source result `-1` for `k > n` remains distinct from this sentinel.
- Negative `k` is excluded because the source does not define it safely.
- For positive `k`, ports sum the first window and then slide using the Java update order `window_sum += incoming - outgoing`, keeping the smallest running sum.

## Upstream review

The pinned Java source `MinSumKSizeSubarray.minSumKSizeSubarray` returns `-1` immediately when the array is shorter than `k`, sums the first `k` values, then scans the remaining windows and retains the minimum. It also deterministically returns zero for `k == 0`. This fixed-size minimum operation is distinct from `max_sum_sliding_window`, which selects the maximum, and from variable-length minimum-subarray algorithms.

Reference: [Java `MinSumKSizeSubarray.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/slidingwindow/MinSumKSizeSubarray.java).

## Implementations

The exported C ABI is `int64_t min_sum_ksize_subarray(const int64_t *values, size_t length)`. Implementations are provided in C, C3, C++, Elisa, Nim, Odin, Rust, V, and Zig. `workload.json` covers ordinary and negative windows, `k == 0`, `k > n`, empty input, malformed packing, and value bounds.

The source-backed oracle is implemented in `benchmarks/run_i64_array_scalar.py`.
