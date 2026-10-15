# Univariate linear regression by ordinary least squares

Fit a straight line to paired observations using ordinary least squares (OLS), then return its slope. This package captures the closed-form univariate fit shared by the pinned C# and Rust implementations; the pinned R implementation delegates fitting to `lm`, which also uses OLS. Java, Julia, and Python candidates use gradient descent and are separate algorithm variants.

## Contract

- The `i64_array_float64` ABI receives `[n, x0, y0, x1, y1, ..., x(n-1), y(n-1)]` as signed 64-bit integers.
- `n` is from 2 through 128. Each coordinate is between -1,000,000 and 1,000,000 inclusive, and the packed array length must equal `1 + 2*n`.
- Valid samples require nonconstant x and nonconstant y. These bounds avoid the zero-variance NaN behavior in the Rust source and the near-zero-x-variance rejection in the C# source.
- Return the fitted slope `sum((x - mean_x) * (y - mean_y)) / sum((x - mean_x)^2)` as binary64.
- Return `-1e300` for malformed input, out-of-range coordinates, fewer than two observations, or zero variance.
- The result tolerance is absolute `1e-10` and relative `1e-12`.
- Fitting takes `O(n)` time and constant auxiliary storage.

## Sources

- [TheAlgorithms C# `LinearRegression.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/MachineLearning/LinearRegression.cs) computes the univariate OLS slope from centered covariance and x variance.
- [TheAlgorithms Rust `linear_regression.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/machine_learning/linear_regression.rs) computes the same slope through Pearson correlation and standard deviations, and returns it with the intercept.
- [TheAlgorithms R `linear_regression.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/regression_algorithms/linear_regression.r) fits an `lm` model and predicts from it; this package restricts that model to one feature.

The pinned [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/machinelearning/LinearRegression.java), [Julia](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/machine_learning/linear_regression.jl), and [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/linear_regression.py) implementations instead use gradient descent, so they are not represented by this OLS contract.

## Workload

[`workload.json`](workload.json) covers positive, negative, and fractional slopes, a non-perfect fit, coordinate bounds, malformed arrays, and zero-variance inputs.

The source-backed expected-value check is in [`benchmarks/run_i64_array_float64.py`](../../run_i64_array_float64.py).

## Implementations

| Language | Port |
| --- | --- |
| C | [`c/l/linear_regression_ols.c`](../../../c/l/linear_regression_ols.c) |
| C3 | [`c3/l/linear_regression_ols.c3`](../../../c3/l/linear_regression_ols.c3) |
| C++ | [`cpp/l/linear_regression_ols.cpp`](../../../cpp/l/linear_regression_ols.cpp) |
| Elisa | [`elisa/l/linear_regression_ols.elisa`](../../../elisa/l/linear_regression_ols.elisa) |
| Nim | [`nim/l/linear_regression_ols.nim`](../../../nim/l/linear_regression_ols.nim) |
| Odin | [`odin/l/linear_regression_ols.odin`](../../../odin/l/linear_regression_ols.odin) |
| Rust | [`rust/l/linear_regression_ols.rs`](../../../rust/l/linear_regression_ols.rs) |
| V | [`v/l/linear_regression_ols.v`](../../../v/l/linear_regression_ols.v) |
| Zig | [`zig/l/linear_regression_ols.zig`](../../../zig/l/linear_regression_ols.zig) |

