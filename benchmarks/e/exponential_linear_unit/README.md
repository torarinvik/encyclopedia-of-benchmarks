# Exponential Linear Unit

Benchmark the pinned Rust source's scalar transformation for one vector element.

## Contract

- The `float64_pair` ABI accepts `[x, alpha]`, corresponding to a one-element vector and the source parameter.
- Both inputs must be finite, with `x` in `[-100, 100]` and `alpha` in `[-1,000,000, 1,000,000]`.
- Preserve the Rust source branch and operation order: for `x < 0`, compute `x * (alpha * (exp(x) - 1))`; otherwise return `x` unchanged. Negative alpha and signed zero are valid.
- Invalid inputs return `-1e300`. Compare valid results with input-scaled tolerance `1e-12`.

## Source semantics

The canonical source is the pinned [Rust implementation](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74a939ec5163648458a8c2b46fd4c/src/math/exponential_linear_unit.rs). Although its documentation describes the conventional ELU negative branch, its code multiplies the original negative value by `alpha * (exp(x) - 1)`. This package preserves the code's actual behavior. The pinned [Python sibling](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/neural_network/activation_functions/exponential_linear_unit.py) instead computes `alpha * (exp(x) - 1)` for nonpositive values, so it is numerically different for negative inputs. The positive branch is identity in both sources.

This is distinct from ReLU, which maps negative inputs to zero, and Leaky ReLU, which multiplies negative inputs directly by alpha.

## Workload

[`workload.json`](workload.json) covers negative inputs, both alpha signs, zero, positive identity, bounds, and invalid values.
