# Cross-Entropy Loss

This package benchmarks the pinned [TheAlgorithms/Rust implementation](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74a4c939ec5163648458a8c2b46fd4c/src/math/cross_entropy_loss.rs). For each paired input it forms the term `-actual[i] * ln(predicted[i])`, stores the terms in order, then sums them in order.

The `i64_array_float64` ABI packs `[n, actual_scaled[0..n], predicted_scaled[0..n]]`. The vectors have equal length `n`, with `1 <= n <= 64`. Each integer is divided by `1,000,000` to obtain its binary64 value. Actual values are in `[0, 1,000,000]`; predicted values are in `[1, 1,000,000]`. This bounded domain keeps all terms finite and allows zero actual entries. It also intentionally excludes the pinned implementation's zip-truncation of unequal arrays, zero or negative predicted values, and arbitrary non-normalized values.

Malformed layouts or out-of-domain values return `-1e300`. Results use absolute and relative tolerance `1e-12`. This computes cross-entropy; the nearby `kl_divergence_loss` source instead compares the two distributions with a logarithmic ratio and an epsilon adjustment. Runtime and auxiliary space are O(n), including the source's intermediate term list.

The shared `run_i64_array_float64.py` runner checks each workload result against the bounded source-ordered term sum before timing.
