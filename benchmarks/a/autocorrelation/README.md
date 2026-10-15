# Autocorrelation

Compute the autocorrelation coefficient of an integer time series at a selected lag, following the pinned Python implementation.

## Contract

- The `i64_array_float64` ABI receives `[count, lag, data...]`, with 2 through 64 data points and `0 <= lag < count`.
- Data values are signed integers in `[-1,000, 1,000]`. A constant series is invalid because its variance is zero.
- Compute the arithmetic mean, population variance `sum((x - mean)^2) / count`, and lagged covariance `sum((x[i] - mean) * (x[i-lag] - mean)) / count`; return covariance divided by variance.
- Both covariance and variance divide by the full series length, matching the source's biased estimator. Invalid lag, packed length, range, or zero variance returns `-1e300`.
- The method takes `O(n)` time and constant auxiliary storage.

## Source

This follows pinned [TheAlgorithms Python `autocorrelation.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/autocorrelation.py). The source rejects lags at least the data length and raises when variance is zero; the benchmark also bounds lag to nonnegative values and maps invalid inputs to the sentinel.

## Workload

[`workload.json`](workload.json) covers the source example, zero and maximum lag, negative and alternating series, constant-series rejection, and malformed input.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/autocorrelation.c`](../../../c/a/autocorrelation.c) |
| C3 | [`c3/a/autocorrelation.c3`](../../../c3/a/autocorrelation.c3) |
| C++ | [`cpp/a/autocorrelation.cpp`](../../../cpp/a/autocorrelation.cpp) |
| Elisa | [`elisa/a/autocorrelation.elisa`](../../../elisa/a/autocorrelation.elisa) |
| Nim | [`nim/a/autocorrelation.nim`](../../../nim/a/autocorrelation.nim) |
| Odin | [`odin/a/autocorrelation.odin`](../../../odin/a/autocorrelation.odin) |
| Rust | [`rust/a/autocorrelation.rs`](../../../rust/a/autocorrelation.rs) |
| V | [`v/a/autocorrelation.v`](../../../v/a/autocorrelation.v) |
| Zig | [`zig/a/autocorrelation.zig`](../../../zig/a/autocorrelation.zig) |

The package uses the `i64_array_float64` ABI and portable scalar operations.
