# Kalman filter (R two-state source variant)

This package benchmarks the deterministic `kalman_filter(observed_prices)` function from the pinned R file. The random data generation, seed, `Metrics` import, and plotting calls are top-level demonstration code; the callable filter accepts its observations directly.

## Contract

- The `float64_slice_io` input is a nonempty observation vector of 1 through 12 finite binary64 values, each in `[-1000,1000]`.
- Initialize `state = [observed_prices[0], 0]`, `P = I`, `Q = 0.0001 I`, `R = 0.1`, `H = [1,0]`, and `A = [[1,0],[1,1]]`. The displayed A matrix preserves R's column-major `matrix(c(1,1,0,1), nrow=2)` construction.
- For every observation, compute `state_pred = A state`, `P_pred = A P A^T + Q`, `K = P_pred H^T / (H P_pred H^T + R)`, then update the state with `state_pred + K * (observation - H state_pred)`. Preserve the source's covariance update `(ones(2,2) - K H) P_pred`; `matrix(1, nrow=2, ncol=2)` is a matrix of ones in R, not an identity matrix.
- Return all filtered state rows as pairs, followed by the final `state_pred` vector and the final `P_pred` matrix in R's column-major order. The result length is `2*n + 6`, at most 30. Comparisons use absolute and relative tolerance `1e-12`.
- Empty input, nonfinite values, and values outside the bound return `-1`. A null output pointer or capacity below the result length returns `-2` without writing; input validation takes precedence.

See the [workload](workload.json) and [oracle](../../kalman_filter_r_two_state_simulation_oracle.py).

## Pinned source

[`kalman_filter.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/quantitative_finance/kalman_filter.r), commit `f65344fabeea0ae33c1ca321af709447c1a8a4c2`, function `kalman_filter`.

## Ports

- [C](../../../c/k/kalman_filter_r_two_state_simulation.c)
- [C++](../../../cpp/k/kalman_filter_r_two_state_simulation.cpp)
- [C3](../../../c3/k/kalman_filter_r_two_state_simulation.c3)
- [Rust](../../../rust/k/kalman_filter_r_two_state_simulation.rs)
- [Elisa](../../../elisa/k/kalman_filter_r_two_state_simulation.elisa)
- [Nim](../../../nim/k/kalman_filter_r_two_state_simulation.nim)
- [Odin](../../../odin/k/kalman_filter_r_two_state_simulation.odin)
- [V](../../../v/k/kalman_filter_r_two_state_simulation.v)
- [Zig](../../../zig/k/kalman_filter_r_two_state_simulation.zig)
