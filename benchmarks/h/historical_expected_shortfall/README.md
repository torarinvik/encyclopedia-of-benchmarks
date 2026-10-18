# Historical expected shortfall

This benchmark maps to `RiskMetrics$calculate_es(..., method = "historical")` in the pinned R source. The `float64_slice_io` input is `[portfolio_value, confidence_level, time_horizon, return_count, returns...]`.

The accepted bounds are portfolio value `[100, 1000000]`, confidence `[0.5, 0.95]`, horizon `[1, 10]`, 20 through 64 finite returns in `[-0.25, 0.25]`, and an exact packed length of `4 + return_count`. The source computes `index = floor((1-confidence)*count)`, selects the first `index` sorted returns using R's 1-based slice `sorted_returns[1:index]`, negates their mean, and scales by portfolio value and `sqrt(time_horizon)`. The contract requires `index >= 1`. The output is a one-element float64 array. Invalid input returns `-1`; a null or undersized output buffer returns `-2` without writes.

The adapter initializes `RiskMetrics` from the supplied returns and calls the historical ES method. The pinned script's demonstration is outside the benchmark; float comparisons use absolute and relative tolerance `1e-10`.

Source: TheAlgorithms/R [`risk_metrics.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/quantitative_finance/risk_metrics.r), commit `f65344fabeea0ae33c1ca321af709447c1a8a4c2`. Workload: [`workload.json`](workload.json). Oracle: [`risk_metrics_oracle.py`](../../risk_metrics_oracle.py), function `expected_result("historical_expected_shortfall", input_values)`.
