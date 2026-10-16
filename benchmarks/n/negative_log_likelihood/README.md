# Negative Log-Likelihood

This package ports the pinned [TheAlgorithms/Rust implementation](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/machine_learning/loss_function/negative_log_likelihood.rs). For each actual/predicted pair it accumulates `-actual * ln(predicted) - (1 - actual) * ln(1 - predicted)`, then divides the ordered sum by the number of pairs. With binary labels this is binary cross-entropy; it is distinct from [`cross_entropy_loss`](../../c/cross_entropy_loss/README.md), which only sums `-actual * ln(predicted)` terms.

The `i64_array_float64` ABI packs `[n, actual_scaled[0..n], predicted_scaled[0..n]]`, with `1 <= n <= 64` and scale `1,000,000`. Actual values range from `0` to `1,000,000`; predicted values range from `1` to `999,999`. The pinned source accepts predicted endpoints, but its formula yields non-finite values there, so this benchmark uses the finite interior domain. Malformed layouts and out-of-range values return `-1e300`.

The shared [`run_i64_array_float64.py`](../../run_i64_array_float64.py) runner checks workload expectations against the pinned source-ordered mean before timing. Results use absolute and relative tolerance `1e-12`.
