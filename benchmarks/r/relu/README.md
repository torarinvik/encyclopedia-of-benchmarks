# ReLU

Apply the rectified linear unit function to one value: `max(0, x)`.

## Contract

- The `float64_unary` ABI accepts one finite, integer-valued binary64 input in `[-16,777,216, 16,777,216]` and returns a binary64 result.
- The supported integers are exactly representable in binary32, so the Rust source's `f32` vector operation agrees exactly with the C# scalar method and Python elementwise operation on this domain.
- Inputs below or above the range, non-finite values, and fractional values return `-1e300`.
- Valid output is exactly zero for `x <= 0`, and `x` for `x > 0`. The workload uses `1e-12` relative and absolute tolerances.

## Source semantics

The canonical candidate is `relu`: pinned [C# `Relu.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Numeric/Relu.cs) applies `Math.Max(0.0, input)`, and pinned [Rust `relu.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/relu.rs) replaces each `f32` vector element less than or equal to zero with zero. The pinned Python candidate named `rectified_linear_unit` applies `np.maximum(0, vector)` and has the same elementwise semantics ([Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/neural_network/activation_functions/rectified_linear_unit.py)). The unary benchmark presents one vector element per call; the integer-valued input bound makes the Rust precision difference immaterial.

## Workload

[`workload.json`](workload.json) covers negative, zero, positive, both bounds, a fractional invalid input, and out-of-range inputs.
