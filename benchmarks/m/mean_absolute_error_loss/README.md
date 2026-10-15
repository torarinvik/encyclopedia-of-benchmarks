# Mean absolute error loss

Compute the average absolute difference between paired predicted and actual values, following the pinned Rust loss function.

## Contract

- The `i64_array_float64` ABI receives `[count, predicted..., actual...]`, with 1 through 256 pairs.
- Each integer value is bounded to `[-1,000,000, 1,000,000]`.
- Return `sum(abs(predicted[i] - actual[i])) / count` as binary64, using relative and absolute tolerance `1e-12`.
- Invalid counts, packed lengths, or values return `-1e300`. The source uses `zip`, so mismatched lengths truncate; the benchmark accepts only equal-length pairs and maps malformed ABI inputs to a sentinel.
- The method takes `O(n)` time and constant auxiliary storage.

## Source

This follows pinned [TheAlgorithms Rust `mean_absolute_error_loss.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/machine_learning/loss_function/mean_absolute_error_loss.rs). It accumulates the absolute difference for each zipped pair and divides by the predicted-list length. The bounded integer contract uses equal-length arrays, preserving the source formula on its intended input domain.

## Workload

[`workload.json`](workload.json) covers the source example on integer inputs, exact matches, positive and negative errors, fractional averages, maximum bounds and length, and malformed inputs.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/m/mean_absolute_error_loss.c`](../../../c/m/mean_absolute_error_loss.c) |
| C3 | [`c3/m/mean_absolute_error_loss.c3`](../../../c3/m/mean_absolute_error_loss.c3) |
| C++ | [`cpp/m/mean_absolute_error_loss.cpp`](../../../cpp/m/mean_absolute_error_loss.cpp) |
| Elisa | [`elisa/m/mean_absolute_error_loss.elisa`](../../../elisa/m/mean_absolute_error_loss.elisa) |
| Nim | [`nim/m/mean_absolute_error_loss.nim`](../../../nim/m/mean_absolute_error_loss.nim) |
| Odin | [`odin/m/mean_absolute_error_loss.odin`](../../../odin/m/mean_absolute_error_loss.odin) |
| Rust | [`rust/m/mean_absolute_error_loss.rs`](../../../rust/m/mean_absolute_error_loss.rs) |
| V | [`v/m/mean_absolute_error_loss.v`](../../../v/m/mean_absolute_error_loss.v) |
| Zig | [`zig/m/mean_absolute_error_loss.zig`](../../../zig/m/mean_absolute_error_loss.zig) |

All ports use portable scalar operations and the shared `i64_array_float64` ABI.
