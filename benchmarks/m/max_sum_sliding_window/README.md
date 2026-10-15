# Maximum sum in a fixed-size window

This benchmark returns the largest sum among all contiguous windows of a fixed length.

## Contract

- Input uses the `i64_array_scalar` ABI and packs `[n, k, value_0, ...]` in a signed 64-bit array.
- `n` is 1 through 100,000, `k` is 1 through `n`, the packed length must be exactly `n + 2`, and each value is in `[-1,000,000,000, 1,000,000,000]`.
- Invalid input returns `INT64_MIN`. Valid sums fit in signed 64-bit arithmetic.
- The result is the maximum sum of any `k` consecutive values. All-negative windows are handled by initializing the maximum from the first window.
- The ports form the first window sum, then update it in source order as `current_sum - outgoing + incoming` while scanning left to right.

## Upstream review

The pinned Python source `max_sum_in_array` uses the rolling-window recurrence described above. The pinned JavaScript `maxSumSubarrayFixed` computes the same fixed-size maximum using an equivalent update order. Their valid-domain results agree for `1 <= k <= n`; Python accepts `k == 0` while JavaScript rejects it, so zero-sized windows are outside this contract. The JavaScript candidate `max_sum_subarray_fixed` is an alias of this benchmark. This operation differs from variable-length maximum-subarray algorithms because every candidate window has exactly `k` values.

References: [Python `max_sum_sliding_window.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/max_sum_sliding_window.py) and [JavaScript `MaxSumSubarrayFixed.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Sliding-Windows/MaxSumSubarrayFixed.js).

## Implementations

The C ABI is `int64_t max_sum_sliding_window(const int64_t *values, size_t length)`. Implementations are provided in C, C3, C++, Elisa, Nim, Odin, Rust, V, and Zig. `workload.json` includes the upstream examples, negative-only windows, singleton and full-array windows, and malformed inputs.

The source-backed oracle is implemented in `benchmarks/run_i64_array_scalar.py`.
