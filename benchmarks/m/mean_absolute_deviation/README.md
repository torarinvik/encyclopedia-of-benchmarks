# Mean absolute deviation

Compute the average absolute distance of each value from the arithmetic mean, following the pinned JavaScript implementation.

## Contract

- The `i64_array_float64` ABI receives `[count, values...]`, with 1 through 256 values.
- Each value is an integer in `[-1,000,000, 1,000,000]`. The bounded integer domain keeps the source sum exact in binary64 before the mean division.
- Return `sum(abs(value - mean(values))) / count` as binary64, using relative and absolute tolerance `1e-12`.
- Invalid counts, packed lengths, or values return `-1e300`. Empty input is excluded because the source's `mean` helper rejects an empty array.
- The source computes the mean and then scans the data again, for `O(n)` time and `O(1)` auxiliary storage.

## Source

This follows pinned [TheAlgorithms JavaScript `MeanAbsoluteDeviation.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/MeanAbsoluteDeviation.js), which imports the arithmetic mean from [`AverageMean.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/AverageMean.js). The benchmark ports the integer input subset and maps source exceptions for malformed or empty inputs to the sentinel.

## Workload

[`workload.json`](workload.json) covers the upstream example, single and constant inputs, fractional means, negative values, the coordinate bounds, maximum length, and malformed input.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/m/mean_absolute_deviation.c`](../../../c/m/mean_absolute_deviation.c) |
| C3 | [`c3/m/mean_absolute_deviation.c3`](../../../c3/m/mean_absolute_deviation.c3) |
| C++ | [`cpp/m/mean_absolute_deviation.cpp`](../../../cpp/m/mean_absolute_deviation.cpp) |
| Elisa | [`elisa/m/mean_absolute_deviation.elisa`](../../../elisa/m/mean_absolute_deviation.elisa) |
| Nim | [`nim/m/mean_absolute_deviation.nim`](../../../nim/m/mean_absolute_deviation.nim) |
| Odin | [`odin/m/mean_absolute_deviation.odin`](../../../odin/m/mean_absolute_deviation.odin) |
| Rust | [`rust/m/mean_absolute_deviation.rs`](../../../rust/m/mean_absolute_deviation.rs) |
| V | [`v/m/mean_absolute_deviation.v`](../../../v/m/mean_absolute_deviation.v) |
| Zig | [`zig/m/mean_absolute_deviation.zig`](../../../zig/m/mean_absolute_deviation.zig) |

The package uses the `i64_array_float64` benchmark ABI and portable scalar operations.
