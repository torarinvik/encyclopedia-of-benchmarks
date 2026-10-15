# One-feature linear regression with sequential gradient updates

This benchmark preserves the update order in the pinned Julia implementation of linear_regression. Each epoch first updates the slope using the current intercept, then recomputes residuals with that new slope to update the intercept. The Julia source records the half-mean-squared error after both updates; this benchmark returns the last value from that history.

The Julia source documentation describes multi-feature matrices, but its initialization and matrix products are dimensionally valid for the one-feature row matrix used by its own example. This package therefore specifies the executable one-feature form and does not claim multi-feature behavior. Its sequential parameter update is distinct from the simultaneous batch update in [linear_regression_gradient_descent](../linear_regression_gradient_descent/README.md).

## Contract

- The i64_array_float64 ABI receives [n, rate_microunits, epochs, x0, y0, ..., x(n-1), y(n-1)] as signed 64-bit integers.
- n is 2 through 64; rate_microunits is 1 through 1,000 and represents alpha = rate_microunits / 1,000,000; epochs are 1 through 10,000.
- Each x is from -10 through 10 and each target y is from -100 through 100. The packed array length must equal 3 + 2*n.
- Initialize slope and intercept to zero. For each epoch, update slope with the sum of x*(slope*x + intercept - y), then update intercept with residuals recomputed using the new slope and the previous intercept. The update scale for each parameter is alpha/n.
- After both updates, compute sum((slope*x + intercept - y)^2)/(2*n). Return the value from the final epoch.
- Return -1e300 for malformed arrays or values outside the bounds. The output tolerance is absolute 1e-10 and relative 1e-12.
- Training takes O(n*epochs) time and constant auxiliary storage.

## Source

- [TheAlgorithms Julia linear_regression.jl](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/machine_learning/linear_regression.jl) initializes weights and bias to zero, performs gradient descent, and appends the half-mean-squared error after each epoch. Its own example reshapes x and y into one-row matrices and calls the algorithm with a learning rate of 0.01 for 1000 iterations.

## Workload

[workload.json](workload.json) covers the sequential update order, multiple epochs, negative and constant-feature data, the minimum rate, and malformed or out-of-range packed inputs.

The shared float64 runner validates each expected final cost by replaying the ordered slope update, intercept update, and squared-error accumulation.

## Implementations

| Language | Port |
| --- | --- |
| C | [C port](../../../c/l/linear_regression_sequential_gradient_descent.c) |
| C3 | [C3 port](../../../c3/l/linear_regression_sequential_gradient_descent.c3) |
| C++ | [C++ port](../../../cpp/l/linear_regression_sequential_gradient_descent.cpp) |
| Elisa | [Elisa port](../../../elisa/l/linear_regression_sequential_gradient_descent.elisa) |
| Nim | [Nim port](../../../nim/l/linear_regression_sequential_gradient_descent.nim) |
| Odin | [Odin port](../../../odin/l/linear_regression_sequential_gradient_descent.odin) |
| Rust | [Rust port](../../../rust/l/linear_regression_sequential_gradient_descent.rs) |
| V | [V port](../../../v/l/linear_regression_sequential_gradient_descent.v) |
| Zig | [Zig port](../../../zig/l/linear_regression_sequential_gradient_descent.zig) |
