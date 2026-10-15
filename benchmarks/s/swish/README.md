# Swish

Benchmark the pinned Python source's Swish activation for one scalar input.

## Contract

- The `float64_unary` ABI accepts one finite binary64 value `x` in `[-100, 100]`.
- The source has an integer `trainable_parameter`; this ABI fixes it to `1`, a supported source value. Preserve the source's expression order: `x * (1 / (1 + exp(-(1 * x))))`.
- Inputs outside the bounded finite domain return `-1e300`. Compare results with relative tolerance `1e-12` and absolute tolerance `1e-15`.

## Source semantics

The pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/neural_network/activation_functions/swish.py) computes `vector * sigmoid(trainable_parameter * vector)`, and its sigmoid is `1 / (1 + exp(-vector))`. This benchmark fixes the parameter at one to fit the existing scalar unary ABI. The source also defines `sigmoid_linear_unit`, equivalent to this fixed-parameter slice; the `swish` function at other parameter values is not represented by this ABI.

With parameter one, Swish is distinct from the benchmarked GELU approximation, which uses a `1.702` sigmoid scale, and from ReLU and Leaky ReLU. The `[-100,100]` bound keeps the exponential finite.

## Workload

[`workload.json`](workload.json) covers negative, zero, positive, boundary, and invalid inputs.
