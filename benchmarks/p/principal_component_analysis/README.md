# Rust principal component analysis

This package covers the pinned Rust `principal_component_analysis` routine. It remains distinct from the R `pca` package: Rust centers unscaled columns, forms population covariance, extracts components by repeated all-ones power iteration and rank-one deflation, and returns only projected scores.

## Contract

The `float64_slice_io` input is `[sample_count, feature_count, component_count, row-major samples×features...]`. The bounded shape is 2–8 samples, 2–4 features, and 1–`feature_count` requested components. Every input value must be finite and within `[-100,100]`.

The source centers each feature and divides covariance sums by `sample_count`. For every requested component it starts power iteration from an all-ones vector, multiplies by the current matrix, normalizes when the norm exceeds `1e-10`, runs at most 1000 iterations, and stops when the largest coordinate change is below `1e-10`. It computes the Rayleigh quotient, subtracts the rank-one eigenpair from the matrix, and projects each centered sample onto the extracted vectors in order. Signs and component ordering follow this iteration and deflation; no extra canonicalization is applied.

To keep the bounded ABI deterministic, accept only inputs for which every iteration has finite intermediates, a norm above `1e-10`, and reaches the source tolerance within 1000 rounds; every Rayleigh quotient and returned score must also be finite. Output is `[sample_count, component_count, row-major projected scores...]`. Invalid framing, shape, bounds, or unstable iteration returns `-1`; insufficient output capacity returns `-2` without writes.

See the [workload](workload.json), [oracle](../../principal_component_analysis_oracle.py), and pinned [`principal_component_analysis`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/machine_learning/principal_component_analysis.rs).
