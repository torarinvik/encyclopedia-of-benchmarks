# One-feature linear regression with stochastic gradient descent

Train a univariate linear model with one gradient update per observation, preserving the pinned Jupyter notebook's ordered per-row updates. The notebook creates its parameters and noisy training targets randomly; this benchmark makes them explicit inputs so every run and language sees the same sequence.

## Contract

- The `i64_array_float64` ABI receives `[n, epochs, rate_microunits, slope0_microunits, intercept0_microunits, x0_microunits, y0_microunits, ...]`.
- `n` is 2..64, epochs are 1..200, and `rate_microunits` is 1..10,000, representing `alpha = rate_microunits / 1,000,000`.
- The initial slope and intercept are in `[-10, 10]`; each feature `x` is in `[-10, 10]`, each target `y` in `[-100, 100]`. These values are encoded as millionths. Packed length must be exactly `5 + 2*n`.
- Each epoch visits rows in input order. For each row, compute `error = slope*x + intercept - y`, then update both parameters from that same error: `slope -= alpha*error*x/n`, `intercept -= alpha*error/n`. This preserves the notebook's per-row optimizer steps and its cost factor `1/(2*n)`; the notebook uses `n_sample=30`, while this bounded benchmark uses the caller's row count.
- Return the final slope as binary64. Return `-1e300` for malformed input or values outside the bounds. The output tolerance is absolute `1e-10` and relative `1e-12`.

## Source semantics

The notebook initializes weight and bias with `np.random.randn`, generates noisy targets with another random draw, and then runs 200 epochs. We replace those uncontrolled random values with caller-supplied initial parameters and training pairs. TensorFlow applies an optimizer step separately for every `(x, y)` pair in the fixed order on each epoch. The notebook also prints costs and plots the final line; those presentation steps are outside this callable contract. This stochastic, ordered update process is distinct from batch gradient descent and Julia's slope-then-intercept sequential update.

## Workload

[`workload.json`](workload.json) covers an exact-fit model, a per-row order-sensitive update, zero features, invalid lengths, and parameter and sample bounds.

The shared float64 runner validates the final slope by replaying the fixed-point inputs and applying the per-row updates in their declared order.

## Pinned source

- [Jupyter `LinearRegression.ipynb`](https://github.com/TheAlgorithms/Jupyter/blob/ebf48b9d0373ae4caccd1d2fad54ad173dbac9e9/machine_learning/Linear_Regression/LinearRegression.ipynb)

## Ports

| Language | Source |
| --- | --- |
| C | [`c/l/linear_regression_stochastic_gradient_descent.c`](../../../c/l/linear_regression_stochastic_gradient_descent.c) |
| C3 | [`c3/l/linear_regression_stochastic_gradient_descent.c3`](../../../c3/l/linear_regression_stochastic_gradient_descent.c3) |
| C++ | [`cpp/l/linear_regression_stochastic_gradient_descent.cpp`](../../../cpp/l/linear_regression_stochastic_gradient_descent.cpp) |
| Elisa | [`elisa/l/linear_regression_stochastic_gradient_descent.elisa`](../../../elisa/l/linear_regression_stochastic_gradient_descent.elisa) |
| Nim | [`nim/l/linear_regression_stochastic_gradient_descent.nim`](../../../nim/l/linear_regression_stochastic_gradient_descent.nim) |
| Odin | [`odin/l/linear_regression_stochastic_gradient_descent.odin`](../../../odin/l/linear_regression_stochastic_gradient_descent.odin) |
| Rust | [`rust/l/linear_regression_stochastic_gradient_descent.rs`](../../../rust/l/linear_regression_stochastic_gradient_descent.rs) |
| V | [`v/l/linear_regression_stochastic_gradient_descent.v`](../../../v/l/linear_regression_stochastic_gradient_descent.v) |
| Zig | [`zig/l/linear_regression_stochastic_gradient_descent.zig`](../../../zig/l/linear_regression_stochastic_gradient_descent.zig) |
