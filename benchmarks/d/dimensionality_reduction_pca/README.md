# Dimensionality reduction PCA slice

This benchmark covers only the one-component PCA routine in the pinned Python `dimensionality_reduction.py` module. It is a bounded split of that umbrella candidate, not a claim that its LDA projection or t-SNE routine is covered.

## Contract

The float64 input slice is `[2, sample_count, 1, feature0_samples..., feature1_samples...]`. It represents a 2 by N feature-by-sample matrix, and requests one component. `sample_count` is from 2 through 8; each sample value must be finite and within `[-1,000,000, 1,000,000]`. The feature covariance uses centered observations and divisor N, as in the source. To make eigenvector sign stable across libraries, the dominant eigenvector is oriented with both entries nonnegative; workloads require positive nonzero covariance and therefore a unique dominant component. The output is the one projected row, in sample order.

The pinned Python source projects the original feature matrix after using centered values to compute the covariance. That behavior is preserved, including its nonzero projected mean when the source data is offset. Invalid shape, selector, sample count, nonfinite value, or nonpositive covariance returns `-1`; insufficient output capacity returns `-2` without writing output.

The shared float64-slice ABI provides the bounded input/output arrays and checks sentinel preservation. See [`workload.json`](workload.json), the [oracle](../../dimensionality_reduction_pca_oracle.py), and the [pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/dimensionality_reduction.py).

| Language | Port |
|---|---|
| C | [`c/d/dimensionality_reduction_pca.c`](../../../c/d/dimensionality_reduction_pca.c) |
| C3 | [`c3/d/dimensionality_reduction_pca.c3`](../../../c3/d/dimensionality_reduction_pca.c3) |
| C++ | [`cpp/d/dimensionality_reduction_pca.cpp`](../../../cpp/d/dimensionality_reduction_pca.cpp) |
| Elisa | [`elisa/d/dimensionality_reduction_pca.elisa`](../../../elisa/d/dimensionality_reduction_pca.elisa) |
| Nim | [`nim/d/dimensionality_reduction_pca.nim`](../../../nim/d/dimensionality_reduction_pca.nim) |
| Odin | [`odin/d/dimensionality_reduction_pca.odin`](../../../odin/d/dimensionality_reduction_pca.odin) |
| Rust | [`rust/d/dimensionality_reduction_pca.rs`](../../../rust/d/dimensionality_reduction_pca.rs) |
| V | [`v/d/dimensionality_reduction_pca.v`](../../../v/d/dimensionality_reduction_pca.v) |
| Zig | [`zig/d/dimensionality_reduction_pca.zig`](../../../zig/d/dimensionality_reduction_pca.zig) |

Run the focused verifier with `python3 benchmarks/verify_float64_slice_io.py --algorithm dimensionality_reduction_pca`.
