# Gaussian Error Linear Unit

Benchmark the pinned Python source's scalar GELU approximation.

## Contract

- The `float64_unary` ABI accepts one finite binary64 value `x` in `[-100, 100]`.
- Preserve the source expression and operation order: `x * (1 / (1 + exp(-1.702 * x)))`.
- Inputs outside the bounded finite domain return `-1e300`. Compare outputs with relative tolerance `1e-12` and absolute tolerance `1e-15`.

## Source semantics

The canonical pinned [Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/neural_network/activation_functions/gaussian_error_linear_unit.py) computes `vector * sigmoid(1.702 * vector)`, where `sigmoid(z)` is `1 / (1 + exp(-z))`. The scalar ports preserve that reciprocal-then-multiply order. The pinned Rust sibling exists at `src/math/gaussian_error_linear_unit.rs` and uses a tanh-based GELU approximation; it is recorded separately as [`gaussian_error_linear_unit_tanh`](../gaussian_error_linear_unit_tanh/README.md).

This approximation is distinct from ReLU, Leaky ReLU, and the exponential linear unit. The finite `[-100,100]` bound keeps the exponential finite and avoids overflow in every port.

## Workload

[`workload.json`](workload.json) covers both signs, zero, the pinned examples, bounds, and invalid values.
