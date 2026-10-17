# Momentum optimizer

This benchmark fixes the callback and hyperparameters of the pinned Rust optimizer to make one reproducible vector update workload. Each call starts with zero velocity, uses the square-function derivative `gradient(x) = 2*x`, learning rate `0.01`, momentum `0.9`, and 100 iterations. Each iteration computes the full gradient from the current vector, updates velocity, then updates the vector in source order.

## Contract

- `float64_slice_io` accepts 1 through 64 finite initial values in `[-1,000,000, 1,000,000]`.
- It returns the final vector with the same number of elements. The output workspace must hold all elements.
- Invalid length, non-finite inputs, or values outside the range return `-1`. A null output or capacity below the input length returns `-2` without writing.
- Results use absolute tolerance `1e-12` and relative tolerance `1e-10` to account for small floating-point differences across compilers.

The original function accepts a general derivative, learning rate, momentum factor, and signed iteration count. This benchmark pins them to the square derivative, `0.01`, `0.9`, and 100 iterations; each invocation retains the source's fresh zero-velocity behavior.

Source: [TheAlgorithms/Rust `momentum.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/machine_learning/optimization/momentum.rs).
