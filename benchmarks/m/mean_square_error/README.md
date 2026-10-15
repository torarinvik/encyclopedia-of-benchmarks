# Mean square error

Compute the mean of squared differences between paired expected and predicted values, following the pinned JavaScript implementation.

## Contract

- The `i64_array_float64` ABI receives `[count, predicted..., expected...]`, with 1 through 256 pairs.
- Every integer value is bounded to `[-1,000,000, 1,000,000]`. At the maximum length, the sum of squared differences remains below `2^53`.
- Return `sum((expected[i] - predicted[i])^2) / count` as binary64, using relative and absolute tolerance `1e-12`.
- Unequal packed lengths, empty data, invalid counts, or out-of-range values return `-1e300`. The source throws for unequal list lengths and yields `NaN` for empty arrays; the ABI maps these cases to the sentinel.
- The method takes `O(n)` time and constant auxiliary storage.

## Source

This follows pinned [TheAlgorithms JavaScript `MeanSquareError.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/MeanSquareError.js). It iterates over the expected values, accumulates each squared difference from the predicted value, and divides by the number of values. The benchmark uses a bounded integer subset so all squared-error sums are exact before the final division.

## Workload

[`workload.json`](workload.json) covers exact and fractional results, negative values, maximum bounds and length, and malformed packed inputs.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/m/mean_square_error.c`](../../../c/m/mean_square_error.c) |
| C3 | [`c3/m/mean_square_error.c3`](../../../c3/m/mean_square_error.c3) |
| C++ | [`cpp/m/mean_square_error.cpp`](../../../cpp/m/mean_square_error.cpp) |
| Elisa | [`elisa/m/mean_square_error.elisa`](../../../elisa/m/mean_square_error.elisa) |
| Nim | [`nim/m/mean_square_error.nim`](../../../nim/m/mean_square_error.nim) |
| Odin | [`odin/m/mean_square_error.odin`](../../../odin/m/mean_square_error.odin) |
| Rust | [`rust/m/mean_square_error.rs`](../../../rust/m/mean_square_error.rs) |
| V | [`v/m/mean_square_error.v`](../../../v/m/mean_square_error.v) |
| Zig | [`zig/m/mean_square_error.zig`](../../../zig/m/mean_square_error.zig) |

The package uses the `i64_array_float64` benchmark ABI and portable scalar operations.
