# Longest subarray with sum less than or equal to k

Find the longest contiguous window whose nonnegative values sum to no more than a target, following TheAlgorithms/Java's linear sliding-window recurrence.

## Contract

- The `i64_array_scalar` input is `[target, n, values...]`. The target and each value are in `0..=2147483647`; `n` is in `0..=256`; and the packed length is exactly `n + 2`.
- To preserve the Java source's signed 32-bit accumulator, the sum of all values must also be at most `2147483647`. This guarantees every intermediate window sum fits without overflow.
- Invalid input returns `-1`; an empty array returns `0`.

## Source

The benchmark follows the pinned Java implementation: [LongestSubarrayWithSumLessOrEqualToK.java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/slidingwindow/LongestSubarrayWithSumLessOrEqualToK.java).

[`workload.json`](workload.json) covers shrinking windows, zero runs, int32 boundary values, total-sum overflow rejection, malformed layouts, and the maximum length.

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm longest_subarray_with_sum_less_or_equal_to_k --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/l/longest_subarray_with_sum_less_or_equal_to_k/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/l/longest_subarray_with_sum_less_or_equal_to_k.c`](../../../c/l/longest_subarray_with_sum_less_or_equal_to_k.c) |
| C3 | [`c3/l/longest_subarray_with_sum_less_or_equal_to_k.c3`](../../../c3/l/longest_subarray_with_sum_less_or_equal_to_k.c3) |
| C++ | [`cpp/l/longest_subarray_with_sum_less_or_equal_to_k.cpp`](../../../cpp/l/longest_subarray_with_sum_less_or_equal_to_k.cpp) |
| Elisa | [`elisa/l/longest_subarray_with_sum_less_or_equal_to_k.elisa`](../../../elisa/l/longest_subarray_with_sum_less_or_equal_to_k.elisa) |
| Nim | [`nim/l/longest_subarray_with_sum_less_or_equal_to_k.nim`](../../../nim/l/longest_subarray_with_sum_less_or_equal_to_k.nim) |
| Odin | [`odin/l/longest_subarray_with_sum_less_or_equal_to_k.odin`](../../../odin/l/longest_subarray_with_sum_less_or_equal_to_k.odin) |
| Rust | [`rust/l/longest_subarray_with_sum_less_or_equal_to_k.rs`](../../../rust/l/longest_subarray_with_sum_less_or_equal_to_k.rs) |
| V | [`v/l/longest_subarray_with_sum_less_or_equal_to_k.v`](../../../v/l/longest_subarray_with_sum_less_or_equal_to_k.v) |
| Zig | [`zig/l/longest_subarray_with_sum_less_or_equal_to_k.zig`](../../../zig/l/longest_subarray_with_sum_less_or_equal_to_k.zig) |
