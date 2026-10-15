# Maximum Sum of a Fixed-Size Subarray

Find the largest sum among all contiguous windows of a requested fixed length `k`. This is a fixed-window operation; the `maximum_subarray` benchmark permits windows of any length.

## Contract

- The `i64_array_scalar` ABI provides one signed 64-bit array. Pack the input as `[a0, a1, ..., a(n-1), k]`, with `k` in the final element.
- Pack zero through 63 array values, each in `-1,000,000..=1,000,000`, followed by `k` as the final value. Thus the packed input contains one through 64 values.
- `k == 0` returns `0`, matching the source's empty-window behavior. For `1 <= k <= n`, return the maximum sum of any contiguous window of exactly `k` array values.
- The source returns `-1` when positive `k` exceeds the array length. Negative `k` would index before the array; this benchmark maps negative `k`, missing `k`, and other malformed or out-of-bound inputs to the shared `-1` sentinel.
- The 63-value bound keeps the source's signed 32-bit running sums in range; the ABI and ports use signed 64-bit values.

## Workload and measurement

[`workload.json`](workload.json) covers single-element windows, full-array windows, sliding updates, and invalid packed inputs. The scalar-array runner records the packed values and checks the expected maximum sum.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/m/max_sum_ksize_subarray.c`](../../../c/m/max_sum_ksize_subarray.c) |
| C3 | [`c3/m/max_sum_ksize_subarray.c3`](../../../c3/m/max_sum_ksize_subarray.c3) |
| C++ | [`cpp/m/max_sum_ksize_subarray.cpp`](../../../cpp/m/max_sum_ksize_subarray.cpp) |
| Elisa | [`elisa/m/max_sum_ksize_subarray.elisa`](../../../elisa/m/max_sum_ksize_subarray.elisa) |
| Nim | [`nim/m/max_sum_ksize_subarray.nim`](../../../nim/m/max_sum_ksize_subarray.nim) |
| Odin | [`odin/m/max_sum_ksize_subarray.odin`](../../../odin/m/max_sum_ksize_subarray.odin) |
| Rust | [`rust/m/max_sum_ksize_subarray.rs`](../../../rust/m/max_sum_ksize_subarray.rs) |
| V | [`v/m/max_sum_ksize_subarray.v`](../../../v/m/max_sum_ksize_subarray.v) |
| Zig | [`zig/m/max_sum_ksize_subarray.zig`](../../../zig/m/max_sum_ksize_subarray.zig) |

## Source

The pinned [TheAlgorithms/Java implementation](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/slidingwindow/MaxSumKSizeSubarray.java) sums the first window, then slides one position at a time by adding the entering value and removing the leaving value. It returns `-1` when the array is shorter than positive `k`, returns zero for `k == 0`, and does not define negative `k` behavior.
