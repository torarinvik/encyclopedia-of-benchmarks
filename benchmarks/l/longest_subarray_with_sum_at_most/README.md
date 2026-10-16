# Longest subarray with sum at most

This benchmark ports TheAlgorithms/JavaScript's longestSubarrayWithSumAtMost, which uses a sliding window to find the longest contiguous subarray whose sum does not exceed a target.

## Contract

- The i64_array_scalar input is [target, n, values...]. The target and each value are in 0..=2147483647; n is in 0..=256; and the packed length is exactly n + 2.
- The benchmark restricts array values to nonnegative integers, matching the sliding-window algorithm's precondition. The empty array returns 0.
- Invalid input returns -1. Valid outputs are lengths from 0 through 256.
- The maximum parseable input length is 259 slots so an over-limit count of 257 can reach the ABI; the maximum valid input is 258 slots.

## Pinned source

- JavaScript [LongestSubarrayWithSumAtMost.js](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Sliding-Windows/LongestSubarrayWithSumAtMost.js)

[workload.json](workload.json) covers empty and maximum-size arrays, exact thresholds, shrinking windows, zero runs, int32 boundaries, malformed inputs, and the over-limit count. The independent oracle is [longest_subarray_with_sum_at_most_oracle.py](../../longest_subarray_with_sum_at_most_oracle.py).

Build and run commands:
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm longest_subarray_with_sum_at_most --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/l/longest_subarray_with_sum_at_most/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithms longest_subarray_with_sum_at_most

## Ports

| Language | Source |
| --- | --- |
| C | [c/longest_subarray_with_sum_at_most.c](../../../c/l/longest_subarray_with_sum_at_most.c) |
| C3 | [c3/longest_subarray_with_sum_at_most.c3](../../../c3/l/longest_subarray_with_sum_at_most.c3) |
| C++ | [cpp/longest_subarray_with_sum_at_most.cpp](../../../cpp/l/longest_subarray_with_sum_at_most.cpp) |
| Elisa | [elisa/longest_subarray_with_sum_at_most.elisa](../../../elisa/l/longest_subarray_with_sum_at_most.elisa) |
| Nim | [nim/longest_subarray_with_sum_at_most.nim](../../../nim/l/longest_subarray_with_sum_at_most.nim) |
| Odin | [odin/longest_subarray_with_sum_at_most.odin](../../../odin/l/longest_subarray_with_sum_at_most.odin) |
| Rust | [rust/longest_subarray_with_sum_at_most.rs](../../../rust/l/longest_subarray_with_sum_at_most.rs) |
| V | [v/longest_subarray_with_sum_at_most.v](../../../v/l/longest_subarray_with_sum_at_most.v) |
| Zig | [zig/longest_subarray_with_sum_at_most.zig](../../../zig/l/longest_subarray_with_sum_at_most.zig) |
