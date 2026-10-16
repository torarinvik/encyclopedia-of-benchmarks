# Mean Absolute Percentage Error

This package benchmarks the pinned [TheAlgorithms/Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/loss_functions.py), method `mean_absolute_percentage_error`. Arithmetic mean of `abs((target - prediction) / target)`, replacing exactly-zero targets with epsilon `1e-15` first.

The `i64_array_float64` ABI packs `[n, y_true_scaled[0..n], y_pred_scaled[0..n]]`. Each fixed-point value is divided by 1,000,000. Vector length is 1..64; each scaled value is in [-1_000_000, 1_000_000]. Inputs must have the exact packed length.

Malformed layouts or out-of-domain values return `-1e300`. Results use absolute and relative tolerance `1e-12`. Runtime and auxiliary space are O(n), including the source’s vectorized intermediate values.
