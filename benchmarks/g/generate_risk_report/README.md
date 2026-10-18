# Generate risk report

This benchmark maps to the pinned R `RiskMetrics$generate_risk_report` method with an explicit deterministic method list `c("historical", "parametric")`. The `float64_slice_io` input is `[portfolio_value, confidence_level, time_horizon, return_count, returns...]`.

The bounds are portfolio value `[100, 1000000]`, confidence `[0.5, 0.95]`, horizon `[1, 10]`, 20 through 64 finite returns in `[-0.25, 0.25]`, and exact length `4 + return_count`. Returns must have nonzero sample standard deviation so the source's skewness and kurtosis fields are finite. The output array contains, in order, historical VaR, historical ES, parametric VaR, parametric ES, mean return, sample volatility, source skewness, and source excess kurtosis. The report's default Monte Carlo entries are excluded by the explicit `include_methods` argument; the Monte Carlo methods have separate contracts and seeded wrappers.

The source formulas are preserved, including the 1-based historical tail index `floor((1-confidence)*count)`, population central moments for skewness/kurtosis, and sample standard deviation. Invalid input returns `-1`; a null or undersized output buffer returns `-2` without writes. Float comparisons use absolute and relative tolerance `1e-10`. The source script's demonstration is not run by the adapter.

Source: TheAlgorithms/R [`risk_metrics.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/quantitative_finance/risk_metrics.r), commit `f65344fabeea0ae33c1ca321af709447c1a8a4c2`. Workload: [`workload.json`](workload.json). Oracle: [`risk_metrics_oracle.py`](../../risk_metrics_oracle.py), function `expected_result("generate_risk_report", input_values)`.
