# Exponential Linear Unit (ELU)

Compute the scalar exponential linear unit from the pinned MATLAB-Octave activation function. The upstream file is an interactive plotting demo; this benchmark isolates its activation expression and supplies the parameter `alpha` as input so all nine language ports perform the same deterministic operation.

## Contract

- The `float64_pair` ABI receives `[x, alpha]`.
- Inputs must be finite, with `x` in `[-100, 100]` and `alpha` in `[-1,000,000, 1,000,000]`. Invalid inputs return `-1e300`.
- For `x < 0`, return `alpha * (exp(x) - 1)`; otherwise return `x`. The value at zero is therefore zero.
- Compare finite results with input-scaled relative tolerance `1e-12`.
- The bound avoids overflow and gives every implementation the same finite input domain. The code uses standard floating-point operations and no architecture-specific instructions.

## Pinned source

The pinned [MATLAB-Octave `ELU.m`](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/machine_learning/Activation%20Functions/ELU.m) plots `alpha * (exp(x) - 1)` for negative `x` and `x` for positive `x`. The source's indicator-multiplied expression also returns zero at `x == 0`.

This is separate from [`exponential_linear_unit`](../exponential_linear_unit/README.md), which preserves a different expression from its pinned Rust source and multiplies the negative input by the alpha-scaled exponential term.

## Implementations

| Language | Port |
| --- | --- |
| C | `c/e/elu.c` |
| C3 | `c3/e/elu.c3` |
| C++ | `cpp/e/elu.cpp` |
| Elisa | `elisa/e/elu.elisa` |
| Nim | `nim/e/elu.nim` |
| Odin | `odin/e/elu.odin` |
| Rust | `rust/e/elu.rs` |
| V | `v/e/elu.v` |
| Zig | `zig/e/elu.zig` |

[`workload.json`](workload.json) covers negative and positive inputs, both alpha signs, zero, signed zero, input bounds, and invalid values. Build and record through the shared `float64_pair` ABI using `benchmarks/run_float64_pair.py`.
