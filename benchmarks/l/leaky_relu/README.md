# Leaky ReLU

Apply the pinned Leaky ReLU operation to one element of a vector.

## Contract

- The `float64_pair` ABI accepts `[x, alpha]`, representing a singleton input vector and its source `alpha` parameter.
- Both values must be finite binary64 numbers in `[-1,000,000, 1,000,000]`.
- Preserve the source branch and operation order: if `x < 0`, return `x * alpha`; otherwise return `x`. Negative alpha values and signed zero are allowed.
- Invalid values return `-1e300`. Valid outputs are checked with input-scaled tolerance `1e-12`.

## Source semantics

The pinned [Rust `leaky_relu.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74a939ec5163648458a8c2b46fd4c/src/math/leaky_relu.rs) clones its input vector and multiplies each element strictly less than zero by `alpha`; all other elements are unchanged. This benchmark calls the same elementwise operation with one value.

## Workload

[`workload.json`](workload.json) covers negative and nonnegative inputs, positive and negative slopes, zero, both input bounds, and invalid out-of-range values.
