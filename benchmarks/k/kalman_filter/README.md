# Scalar Kalman filter trace

This package follows the pinned Java scalar `KalmanFilter`. Each measurement
uses the source's `filter(measurement)` cycle: predict with zero control, then
correct with the constructor's default measurement noise. The trace starts from
the constructor's initial estimate and covariance.

## Contract

- The `float64_slice_io` input is
  `[initial_estimate_micro, initial_covariance_micro, process_noise_micro,
  measurement_noise_micro, step_count, measurement_micro...]`.
- Micro-unit fields are finite integer-valued doubles divided by `1e6` before
  use. The initial estimate and measurements are in `[-1000, 1000]`; initial
  covariance and process noise are in `[0, 1_000_000]`; default measurement
  noise is in `[1e-6, 1_000_000]`. The step count is an integer from 1 through
  12. Input length must equal `5 + step_count`; at most 64 words are parsed.
- For each measurement, preserve the Java update order:
  `p += q`, `innovation = p + r`, `gain = p / innovation`,
  `x += gain * (z - x)`, then `p = p * r / innovation`. The covariance uses
  multiplication by `r` before division; the benchmark does not replace this
  expression with `(1 - gain) * p`.
- Output is three doubles per step in trace order:
  `[estimate, error_covariance, last_gain]`. The return value is the number of
  output doubles, `3 * step_count`, up to 36. Comparisons use absolute and
  relative tolerance `1e-12`.
- Malformed framing, nonfinite or fractional micro-unit values, and values
  outside the stated bounds return `-1`. A null output pointer or capacity
  below the required element count returns `-2` without writing. Input
  validation precedes output-buffer checks.

This bounded trace covers the Java `filter(double)` state transition and its
default sensor noise. Java's control-input overload, per-update noise override,
and static sensor-fusion helper are outside this contract. The R source is a
separate randomized two-state simulation and is not mapped to this benchmark.

[`workload.json`](workload.json) and the independent
[`kalman_filter_oracle.py`](../../kalman_filter_oracle.py) define deterministic
traces, state boundaries, malformed inputs, and output-buffer probes.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/k/kalman_filter.c`](../../../c/k/kalman_filter.c) |
| C3 | [`c3/k/kalman_filter.c3`](../../../c3/k/kalman_filter.c3) |
| C++ | [`cpp/k/kalman_filter.cpp`](../../../cpp/k/kalman_filter.cpp) |
| Elisa | [`elisa/k/kalman_filter.elisa`](../../../elisa/k/kalman_filter.elisa) |
| Nim | [`nim/k/kalman_filter.nim`](../../../nim/k/kalman_filter.nim) |
| Odin | [`odin/k/kalman_filter.odin`](../../../odin/k/kalman_filter.odin) |
| Rust | [`rust/k/kalman_filter.rs`](../../../rust/k/kalman_filter.rs) |
| V | [`v/k/kalman_filter.v`](../../../v/k/kalman_filter.v) |
| Zig | [`zig/k/kalman_filter.zig`](../../../zig/k/kalman_filter.zig) |

## Pinned source

- [TheAlgorithms/Java `KalmanFilter.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/streaming/KalmanFilter.java)
