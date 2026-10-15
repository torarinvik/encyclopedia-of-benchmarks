# Median of Two Sorted Arrays by Binary Partition

This benchmark preserves the logarithmic-time method in TheAlgorithms/Java's `MedianOfTwoSortedArrays`: binary-search a partition in the shorter input array, derive the matching partition in the longer array, and adjust until the left side contains the lower half of the combined values.

## Contract

- Encode input as `[first_length, second_length, first_values..., second_values...]` in signed 64-bit integers.
- Each array has at most 1,000 values; the combined total must be 1 through 2,000. Values are in `[-1,000,000, 1,000,000]`, and both arrays must be sorted in nondecreasing order.
- Return twice the exact median: `2 * middle` for odd totals, or the sum of the two middle values for even totals. This avoids floating-point output in the scalar ABI.
- Invalid input returns `-2,000,001`, outside the valid result range `[-2,000,000, 2,000,000]`. Inputs are read-only.
- Validation scans both arrays, so total time is `O(m+n)`; the median partition search itself is `O(log(min(m,n)))`. Auxiliary space is `O(1)`.

## Workload

[`workload.json`](workload.json) includes published examples, an empty side, odd and even combined sizes, a valid result of `-1`, negative and duplicate boundaries, malformed arrays, out-of-domain values, and the maximum input size.

Build with the `i64_array_scalar` ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm median_of_two_sorted_arrays_partition --language rust
```

The C LeetCode 4 benchmark [`median_of_two_sorted_arrays`](../median_of_two_sorted_arrays/README.md) uses a linear merge. This benchmark captures the distinct Java binary-partition algorithm.

## Upstream reference

- [TheAlgorithms/Java `MedianOfTwoSortedArrays.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/divideandconquer/MedianOfTwoSortedArrays.java)
