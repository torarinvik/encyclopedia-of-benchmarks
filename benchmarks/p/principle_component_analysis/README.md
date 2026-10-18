# Python principal component analysis

This package measures `apply_pca` from the pinned Python source. It uses the source's `StandardScaler` followed by `sklearn.decomposition.PCA`; it is distinct from the R `pca` candidate and the Rust `principal_component_analysis` candidate.

## Contract

Input is `[sample_count, feature_count, component_count, row-major samples-by-features...]`. The finite benchmark domain has 3–8 samples, 2–4 features, strictly more samples than features, exact integer values in `[-9,9]`, and nonconstant columns. The covariance spectrum must have positive, pairwise separated eigenvalues (gap greater than `1e-8`) so the selected directions are deterministic.

The benchmark pins scikit-learn 1.4.2 because PCA's sign convention changed in 1.5. It standardizes each feature with `StandardScaler` (population variance), then calls `PCA(n_components=...)`. For these bounded small matrices the `auto` solver selects the full SVD. PCA centers the scaled matrix again and estimates explained variance with `sample_count - 1` degrees of freedom. Scores are returned row-major, followed by the selected `explained_variance_ratio_` values. In 1.4.2, full-SVD `svd_flip(U,Vt)` uses the largest-magnitude entry in each left singular vector to choose a positive sign, choosing the first sample on a tie. The eigenvalue gap restriction excludes ambiguous singular subspaces.

The deterministic oracle diagonalizes the equivalent small symmetric covariance matrix with Jacobi rotations. It accepts only finite, full-rank, separated spectra. Input errors return `-1`; null output or insufficient capacity returns `-2` without writes. The fixed Iris loader and printing `main` are not part of the benchmarked operation; the package measures the reusable `apply_pca(data_x, n_components)` function.

See the [workload](workload.json), [oracle](../../principle_component_analysis_oracle.py), and pinned [`principle_component_analysis.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/principle_component_analysis.py). The relevant [scikit-learn 1.4.2 PCA code](https://github.com/scikit-learn/scikit-learn/blob/1.4.2/sklearn/decomposition/_pca.py) and [`svd_flip`](https://github.com/scikit-learn/scikit-learn/blob/1.4.2/sklearn/utils/extmath.py) define the dependency behavior. The upstream function returns both transformed scores and explained-variance ratios; the adjacent R and Rust sources have different scaling, covariance, output, and iteration semantics.
