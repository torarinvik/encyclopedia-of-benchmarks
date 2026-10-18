# Monte Carlo value at risk

This benchmark maps to `RiskMetrics$calculate_var(..., method = "monte_carlo")` in the pinned R source. The `float64_slice_io` input is `[portfolio_value, confidence_level, time_horizon, simulation_count, return_count, returns..., standardized_normal_draws...]`.

The accepted bounds are portfolio value `[100, 1000000]`, confidence `[0.5, 0.95]`, horizon `[1, 10]`, 20 through 128 simulations, and 20 through 64 returns in `[-0.25, 0.25]` with nonzero sample standard deviation. The input includes exactly one standardized normal draw per simulation, each in `[-3, 3]`. The wrapper applies the source `rnorm` transformation in draw order, `mean(returns) + sample_sd(returns) * z[i]`, then preserves the source sort, one-based tail index `floor((1-confidence)*simulation_count)`, negative loss, and horizon scaling. The index must be at least 1. This deterministic draw injection replaces only RNG generation; the source formula and one independent draw stream for this method remain explicit. The output is a one-element float64 array.

Invalid input returns `-1`; a null or undersized output buffer returns `-2` without writes. Float comparisons use absolute and relative tolerance `1e-10`. The pinned script's demonstration is outside the benchmark.

Source: TheAlgorithms/R [`risk_metrics.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/quantitative_finance/risk_metrics.r), commit `f65344fabeea0ae33c1ca321af709447c1a8a4c2`. Workload: [`workload.json`](workload.json). Oracle: [`risk_metrics_oracle.py`](../../risk_metrics_oracle.py), function `expected_result("monte_carlo_var", input_values)`.
