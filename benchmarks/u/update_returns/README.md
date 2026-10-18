# Update risk returns

This benchmark maps to the pinned R `RiskMetrics$update_returns` method. Its `float64_slice_io` input is `[new_return_count, new_returns...]`, with 2 through 60 finite values in `[-0.25, 0.25]`, nonzero sample standard deviation, and exact packed length `1 + new_return_count`.

The adapter starts from a `RiskMetrics` instance initialized with fixed prior returns `[-0.01, 0.01]`, calls `update_returns(new_returns)`, then projects observable state as `[updated returns..., mean_return, volatility, parametric_var_after_update]`. The final value calls the source's parametric VaR method with portfolio value `100000`, confidence `0.95`, and horizon `1`, confirming that the private fitted statistics were updated. The source method itself returns the object invisibly; this explicit output projection makes the mutation comparable across the float64 slice ABI. The adapter creates its instance during setup before timed samples.

Invalid input returns `-1`; a null or undersized output buffer returns `-2` without writes. Output length is `new_return_count + 3`, at most 63 values. Float comparisons use absolute and relative tolerance `1e-10`. The source script's demonstration is not run by the adapter.

Source: TheAlgorithms/R [`risk_metrics.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/quantitative_finance/risk_metrics.r), commit `f65344fabeea0ae33c1ca321af709447c1a8a4c2`. Workload: [`workload.json`](workload.json). Oracle: [`risk_metrics_oracle.py`](../../risk_metrics_oracle.py), function `expected_result("update_returns", input_values)`.
