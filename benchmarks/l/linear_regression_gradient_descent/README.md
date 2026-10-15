# Univariate linear regression by batch gradient descent

Train a one-feature linear model from zero slope and intercept, then return the trained slope. This contract follows the batch update shared by the pinned Java `fit` method and the Python `run_steep_gradient_descent` helper. It makes the helper's step size and iteration count explicit and uses the true observation count in the normalization.

## Contract

- The `i64_array_float64` ABI receives `[n, rate_microunits, epochs, x0, y0, ..., x(n-1), y(n-1)]` as signed 64-bit integers.
- `n` is 2 through 64; `rate_microunits` is 1 through 1,000 and represents `alpha = rate_microunits / 1,000,000`; epochs are 1 through 10,000.
- Each x feature is from -10 through 10, and each y target is from -100 through 100. The packed array length must equal `3 + 2*n`.
- Initialize slope and intercept to zero. On each batch epoch, compute residual `slope*x + intercept - y` for every observation, then update both parameters by `alpha/n` times their summed gradients. Return the final slope as binary64.
- The Java source updates each parameter with `2.0 / n * gradient * learningRate`; its learning rate is set to `alpha/2` to match the Python helper's `alpha/n` update. Python's outer driver fixes its rate and iteration count and passes `n-1` as the helper denominator; this package uses the reusable helper with the actual count `n`.
- Return `-1e300` for malformed arrays or values outside the bounds. The output tolerance is absolute `1e-10` and relative `1e-12`.
- Training takes `O(n*epochs)` time and constant auxiliary storage.

## Sources

- [TheAlgorithms Java `LinearRegression.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/machinelearning/LinearRegression.java) initializes both parameters to zero and performs batch gradient descent over all training points each epoch.
- [TheAlgorithms Python `linear_regression.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/linear_regression.py) provides `run_steep_gradient_descent`, which applies one batch update to the intercept-plus-feature vector. Its top-level driver fetches a dataset and plots results; those I/O steps are outside this contract.

The pinned [Jupyter notebook](https://github.com/TheAlgorithms/Jupyter/blob/ebf48b9d0373ae4caccd1d2fad54ad173dbac9e9/machine_learning/Linear_Regression/LinearRegression.ipynb) is not included: it uses TensorFlow's per-observation stochastic updates and random parameter initialization. The pinned Julia implementation uses matrix-valued features and returns weights, bias, and an iteration history, so it needs a separate multivariate contract.

## Workload

[`workload.json`](workload.json) covers positive and negative one-epoch updates, multiple epochs, symmetric inputs, bounds, and invalid packed shapes and parameters.

The shared float64 runner validates each expected slope by replaying the ordered residual sums and batch parameter updates.

## Implementations

| Language | Port |
| --- | --- |
| C | [`c/l/linear_regression_gradient_descent.c`](../../../c/l/linear_regression_gradient_descent.c) |
| C3 | [`c3/l/linear_regression_gradient_descent.c3`](../../../c3/l/linear_regression_gradient_descent.c3) |
| C++ | [`cpp/l/linear_regression_gradient_descent.cpp`](../../../cpp/l/linear_regression_gradient_descent.cpp) |
| Elisa | [`elisa/l/linear_regression_gradient_descent.elisa`](../../../elisa/l/linear_regression_gradient_descent.elisa) |
| Nim | [`nim/l/linear_regression_gradient_descent.nim`](../../../nim/l/linear_regression_gradient_descent.nim) |
| Odin | [`odin/l/linear_regression_gradient_descent.odin`](../../../odin/l/linear_regression_gradient_descent.odin) |
| Rust | [`rust/l/linear_regression_gradient_descent.rs`](../../../rust/l/linear_regression_gradient_descent.rs) |
| V | [`v/l/linear_regression_gradient_descent.v`](../../../v/l/linear_regression_gradient_descent.v) |
| Zig | [`zig/l/linear_regression_gradient_descent.zig`](../../../zig/l/linear_regression_gradient_descent.zig) |

