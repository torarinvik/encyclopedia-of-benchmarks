# R principal component analysis

This package covers the `pca_algorithm` implementation in the pinned TheAlgorithms/R source. It is distinct from the R `princomp(train, cor = TRUE)` dataset snippet and from the Python and Rust PCA candidates.

## Contract

The `float64_slice_io` input is `[sample_count, feature_count, component_count, X...]`, where `X` is a row-major sample-by-feature matrix. This bounded slice fixes `feature_count = 2`, `component_count = 1`, and `sample_count` in 3..8. Each sample value must be finite and within `[-1000, 1000]`, and both feature columns must have nonzero sample variance.

The source calls `scale(X)`, which centers each column and divides by its sample standard deviation, then computes `cov(X_std)` with sample covariance. It uses the leading eigenpair of that 2x2 covariance matrix, with eigenvalues in descending order, and projects the standardized data onto the selected component. The benchmark emits one flat result sequence: all projected scores in sample order, the selected component vector in feature order, then both eigenvalues in descending order.

The source does not specify eigenvector signs, so the cross-language contract makes them deterministic: orient the selected vector so its largest-magnitude coordinate is positive, choosing the first coordinate on an absolute-value tie, and apply the same sign to the scores. Matrices whose leading eigenvalue is within `1e-8` of the second are excluded. Invalid framing, dimensions, values, zero-variance columns, or an ambiguous leading eigenvalue return `-1`; insufficient output capacity returns `-2` without writes.

See the [workload](workload.json), [oracle](../../pca_oracle.py), and pinned [`pca_algorithm`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/data_preprocessing/pca.r).
