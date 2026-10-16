# Gradient boosting regressor

This contract benchmarks the custom squared-error gradient boosting implementation in the pinned R source. It uses a bounded one-feature training set and depth-one regression trees (stumps), so the complete fitting and prediction path is deterministic and portable.

## Contract

Input is `[sample_count, estimator_count, learning_rate_micros, query_x, x..., target_y_milli...]`. There are 2–16 training samples; feature values are strictly increasing integers in `[-1000, 1000]`; target values are integer thousandths in `[-1,000,000, 1,000,000]`; and the query feature is in `[-1000, 1000]`. The estimator count is 1–12 and learning rate is 1–1,000,000 micro-units. Malformed inputs return `-1e300`.

The initial prediction is the arithmetic mean of the training targets. Each estimator fits a depth-one regression tree to the residuals. Candidate split thresholds are midpoints between adjacent features; the split with minimum sum of squared error is selected, with ties going to the first threshold. Leaf outputs are residual means. If residuals are constant, the stump is a single mean-valued leaf. Each iteration adds `learning_rate * stump_prediction` to training and query predictions. The returned value is the query prediction in target units.

This fixes the R source's `max_depth` to one and `min_samples_split` to two, bounds the data, and returns a single prediction rather than exposing the mutable R6 model object. It preserves the source's mean initialization, squared-error residual updates, midpoint split search, and mean-valued leaves. The source's optional feature-importance method refers to `X` outside its scope; that method is excluded.

## Verification

Eight ports pass `python3 benchmarks/verify_i64_array_float64.py --algorithm gradient_boosting_regressor --languages c c3 cpp nim odin rust v zig`. The Elisa source is present but not runtime-verified: the configured stage1 backend (`../Elisa-compiler/bin/elisac-stage1`) declines `gradient_boosting_regressor_impl` with `call expression` and emits no object.

## Pinned source

- TheAlgorithms/R [`machine_learning/gradient_boosting.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/machine_learning/gradient_boosting.r)

## Implementations

C, C3, C++, Elisa, Nim, Odin, Rust, V, and Zig implementations are in their corresponding language `g/gradient_boosting_regressor` directories.
