# Linear Regression Cost

Compute the half-mean-squared error for a feature matrix, parameter vector, and target vector. The benchmark follows the pinned MATLAB/Octave `computecost` function and handles multiple features, including a caller-supplied intercept column.

## Contract

- Input is `[m, d, X_row_major..., theta..., y...]`, where `m` is the observation count, `d` is the feature count, `X` contains `m*d` row-major feature values, `theta` contains `d` weights, and `y` contains `m` targets.
- `m` is 1 through 64 and `d` is 1 through 16. Every feature, weight, and target is an integer from -1,000 through 1,000. The packed length must equal `2 + m*d + d + m`.
- Return `sum((X*theta - y)^2)/(2*m)` as binary64. The input bounds keep intermediates finite and within the precision needed by the shared tolerance.
- Malformed input returns `-1e300`. Output tolerance is absolute `1e-10` and relative `1e-12`.
- Each call takes `O(m*d)` time and constant auxiliary storage.

The ABI uses integer-valued samples as a portable subset of the source's double-valued matrix inputs. It keeps the full multivariate dot-product and squared-error calculation and does not include dataset loading, plotting, or console pauses.

## Source

- [TheAlgorithms MATLAB/Octave `computecost.m`](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/machine_learning/Linear-Regression/computecost.m) computes each prediction with `x * Theta`, subtracts `Y`, squares the residuals, sums them, and divides by `2*length(Y)`. The repository is licensed under [MIT](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/LICENSE).

[`workload.json`](workload.json) covers zero and nonzero costs, negative values, multiple features, one observation, maximum dimensions, malformed layouts, and out-of-range components. [`benchmarks/linear_regression_cost_oracle.py`](../../linear_regression_cost_oracle.py) independently computes the bounded matrix-vector residual cost.

Build and verify with the shared binary64 ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm linear_regression_cost --language rust
python3 benchmarks/verify_i64_array_float64.py --algorithm linear_regression_cost
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/l/linear_regression_cost.c`](../../../c/l/linear_regression_cost.c) |
| C3 | [`c3/l/linear_regression_cost.c3`](../../../c3/l/linear_regression_cost.c3) |
| C++ | [`cpp/l/linear_regression_cost.cpp`](../../../cpp/l/linear_regression_cost.cpp) |
| Elisa | [`elisa/l/linear_regression_cost.elisa`](../../../elisa/l/linear_regression_cost.elisa) |
| Nim | [`nim/l/linear_regression_cost.nim`](../../../nim/l/linear_regression_cost.nim) |
| Odin | [`odin/l/linear_regression_cost.odin`](../../../odin/l/linear_regression_cost.odin) |
| Rust | [`rust/l/linear_regression_cost.rs`](../../../rust/l/linear_regression_cost.rs) |
| V | [`v/l/linear_regression_cost.v`](../../../v/l/linear_regression_cost.v) |
| Zig | [`zig/l/linear_regression_cost.zig`](../../../zig/l/linear_regression_cost.zig) |
