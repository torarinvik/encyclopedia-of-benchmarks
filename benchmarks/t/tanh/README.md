# Hyperbolic tangent

Compute the hyperbolic tangent of one binary64 value.

## Contract

- The `float64_unary` ABI accepts one finite binary64 value `x` in `[-10, 10]` and returns binary64.
- The normalized formula is `(2 / (1 + exp(-2 * x))) - 1`, in that operation order.
- Inputs outside the range or non-finite values return `-1e300`.
- Results use relative tolerance `1e-6` and absolute tolerance `1e-7`.

## Source semantics

The pinned [C# `Tanh.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Numeric/Tanh.cs) calls `Math.Tanh`. Pinned [Python `tanh.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/tanh.py) uses the logistic identity `(2 / (1 + exp(-2*x))) - 1` over an array. Pinned [Rust `tanh.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74a939ec5163648458a8c2b46fd4c/src/math/tanh.rs) applies that identity to a mutable `f32` vector. The benchmark normalizes all ports to the logistic identity in binary64, while the Rust port retains the source's binary32 calculation; the stated tolerance covers its rounding differences.

## Workload

[`workload.json`](workload.json) covers negative, zero, and positive values, the supported endpoints, and invalid out-of-range inputs.
