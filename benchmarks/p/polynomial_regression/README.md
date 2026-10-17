# Polynomial regression

This benchmark covers fitting a univariate polynomial regression model and predicting values from the fitted model, following the pinned Python implementation. Its plotting and dataset demonstration are excluded.

## Contract

The ABI is `float64_slice_io`. Input is `[degree, training_count, query_count, x_train..., y_train..., x_query...]`. Degree is an exact integer from 0 through 3; there are `degree+1` through 5 training points and 1 through 4 query points. Training abscissas are pairwise-distinct integers in `[-2,2]`; query abscissas are integers in `[-2,2]` and may repeat or overlap training values. Responses are integer-valued in `[-32,32]`.

The design matrix is the increasing-power Vandermonde matrix: row `i` is `[1, x_i, x_i^2, ..., x_i^degree]`. Fit the least-squares coefficients using the Moore-Penrose pseudoinverse, as in the source's SVD-based `pinv(X) @ y_train`; then predict by evaluating the same design matrix for each query abscissa and multiplying by the fitted coefficients. Pairwise-distinct bounded training abscissas and `degree < training_count` guarantee a comfortably full-rank design in this domain. The output is `[beta_0, ..., beta_degree, prediction_0, ..., prediction_(query_count-1)]`. Values are compared as float64 with absolute and relative tolerance `1e-9`.

Malformed framing, unsupported bounds, fractional integer fields, repeated training abscissas, or non-finite values return `-1` before output checks. A null output buffer or capacity below the required element count returns `-2` without writes.

## Pinned source

- Python `PolynomialRegression._design_matrix`, `fit`, and `predict`: https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/polynomial_regression.py

The source constructs the design matrix in increasing-power order, rejects rank-deficient fits, and computes the pseudoinverse using SVD. Matplotlib plotting and the seaborn demo are outside the workload.

## Workload and oracle

- Workload: [`workload.json`](workload.json)
- Oracle: [`polynomial_regression_oracle.py`](../../polynomial_regression_oracle.py)

## Ports

| Language | Source |
| --- | --- |
| C | [`c/p/polynomial_regression.c`](../../../c/p/polynomial_regression.c) |
| C3 | [`c3/p/polynomial_regression.c3`](../../../c3/p/polynomial_regression.c3) |
| C++ | [`cpp/p/polynomial_regression.cpp`](../../../cpp/p/polynomial_regression.cpp) |
| Elisa | [`elisa/p/polynomial_regression.elisa`](../../../elisa/p/polynomial_regression.elisa) |
| Nim | [`nim/p/polynomial_regression.nim`](../../../nim/p/polynomial_regression.nim) |
| Odin | [`odin/p/polynomial_regression.odin`](../../../odin/p/polynomial_regression.odin) |
| Rust | [`rust/p/polynomial_regression.rs`](../../../rust/p/polynomial_regression.rs) |
| V | [`v/p/polynomial_regression.v`](../../../v/p/polynomial_regression.v) |
| Zig | [`zig/p/polynomial_regression.zig`](../../../zig/p/polynomial_regression.zig) |
