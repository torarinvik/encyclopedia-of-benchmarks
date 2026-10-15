# Maximum sum of a distinct fixed-size window

This benchmark returns the greatest sum of a length-`k` contiguous window whose values are all distinct.

## Contract

- Input uses the `i64_array_scalar` ABI and packs `[n, k, value_0, ...]` in a signed 64-bit array.
- `n` is 1 through 8,192, `k` is 1 through `n`, the packed length must be exactly `n + 2`, and every value must fit signed 32-bit range.
- Invalid packing or out-of-domain values return `INT64_MIN`.
- The source initializes its maximum to zero. Therefore, no all-distinct window and windows whose sums are all negative both produce zero. Positive and zero valid-window sums can raise the result.
- The ports maintain a rolling sum and a bounded open-addressing last-seen table. A window ending at index `i` is all-distinct exactly when its start is at or after the start of the current longest distinct suffix. This enforces the source's frequency-map predicate with the same linear scan and result semantics.
- The maximum possible absolute sum fits signed 64-bit arithmetic because there are at most 8,192 signed 32-bit values.

## Upstream review

The pinned Java `maximumSubarraySum` maintains a fixed-size rolling sum and a frequency map, updating the maximum only when the current window has `k` distinct elements. It returns zero for `k <= 0`, for `n < k`, when there is no distinct window, and when all valid sums are negative. This benchmark uses the shared valid subset `1 <= k <= n`; the baseline-zero behavior for negative or absent distinct-window sums is retained.

This is distinct from `maximum_unique_subarray`, which maximizes over variable-length distinct subarrays, and from `max_sum_sliding_window`, which accepts repeated values in fixed-size windows.

Reference: [Java `MaximumSumOfDistinctSubarraysWithLengthK.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/others/MaximumSumOfDistinctSubarraysWithLengthK.java).

## Implementations

The exported C ABI is `int64_t maximum_sum_of_distinct_subarrays_with_length_k(const int64_t *values, size_t length)`. Implementations are provided in C, C3, C++, Elisa, Nim, Odin, Rust, V, and Zig. `workload.json` includes a positive result, a duplicate-only case with no valid window, all-negative distinct windows, and malformed inputs.

The shared `i64_array_scalar` runner checks every workload with a bounded fixed-window frequency and sum oracle, retaining the source's zero baseline and signed-32-bit item range.
