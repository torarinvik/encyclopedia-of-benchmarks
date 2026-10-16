# Dimensionality reduction LDA slice

This benchmark covers the linear-discriminant projection method in the pinned Python `dimensionality_reduction.py` umbrella. It is a separate contract from the PCA split; seeded t-SNE remains unresolved.

## Contract

The float64 input slice is `[2, sample_count, 2, 1, feature0_samples..., feature1_samples..., labels...]`. It represents a 2 by N feature-by-sample matrix, two classes labeled `0` and `1`, and requests one output dimension. `sample_count` is from 4 through 8, every feature is finite and in `[-10,000, 10,000]`, and each class has at least two samples. The pooled within-class covariance must be positive definite with determinant greater than `1e-12`, and the class means must differ.

The pinned method computes between/within covariance matrices, selects the largest generalized eigenvector, applies SVD to the selected vector, then projects the original feature matrix. In this bounded two-class, two-feature case, the selected direction is proportional to `within_covariance^-1 * (class1_mean - class0_mean)`. The benchmark normalizes it to unit Euclidean length and chooses a deterministic sign (first nonzero component positive), because the source library does not guarantee eigenvector sign. Output is that direction dotted with each original sample, in sample order.

Invalid metadata, labels, counts, feature bounds, or singular within-class covariance return `-1`; insufficient output capacity returns `-2` without writes. The workload includes malformed labels and singular covariance.

See [`workload.json`](workload.json), the [oracle](../../dimensionality_reduction_lda_oracle.py), and the [pinned Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/dimensionality_reduction.py).

| Language | Port |
|---|---|
| C | [`c/d/dimensionality_reduction_lda.c`](../../../c/d/dimensionality_reduction_lda.c) |
| C3 | [`c3/d/dimensionality_reduction_lda.c3`](../../../c3/d/dimensionality_reduction_lda.c3) |
| C++ | [`cpp/d/dimensionality_reduction_lda.cpp`](../../../cpp/d/dimensionality_reduction_lda.cpp) |
| Elisa | [`elisa/d/dimensionality_reduction_lda.elisa`](../../../elisa/d/dimensionality_reduction_lda.elisa) |
| Nim | [`nim/d/dimensionality_reduction_lda.nim`](../../../nim/d/dimensionality_reduction_lda.nim) |
| Odin | [`odin/d/dimensionality_reduction_lda.odin`](../../../odin/d/dimensionality_reduction_lda.odin) |
| Rust | [`rust/d/dimensionality_reduction_lda.rs`](../../../rust/d/dimensionality_reduction_lda.rs) |
| V | [`v/d/dimensionality_reduction_lda.v`](../../../v/d/dimensionality_reduction_lda.v) |
| Zig | [`zig/d/dimensionality_reduction_lda.zig`](../../../zig/d/dimensionality_reduction_lda.zig) |

Run `python3 benchmarks/verify_float64_slice_io.py --algorithm dimensionality_reduction_lda` to verify all nine ports.
