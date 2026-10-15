# False position

## Contract

Approximate a root of the fixed function `f(x) = x² - x` using the bracket-preserving false-position method. The two binary64 inputs are ordered by function sign: `a` must lie in `[0.125, 0.875]`, where `f(a) < 0`; `b` must lie in `[-2, -0.125]` or `[1.125, 3]`, where `f(b) > 0`. If `b < 0`, the bracket isolates root 0; if `b > 1`, it isolates root 1. The output is the root approximation. Invalid inputs return `-1.0`.

Each update computes the x-intercept of the line through `(a, f(a))` and `(b, f(b))`, then replaces the endpoint with the same function-value sign as the new point. The solver stops at residual `|f(c)| <= 1e-12` or after 256 updates. All ports use binary64 arithmetic and portable scalar operations.

The C++ helper in the pinned source recursively moves endpoints without checking the new function sign, so it can lose the sign-changing bracket. Its default `x² - x` scan uses a `0.5` step and lands exactly on both roots, so that main routine does not exercise the helper. The MATLAB source expresses the bracket-preserving update with function-sign checks; this shared benchmark follows that intended method and standardizes the callback to the C++ source's quadratic.

## Workload and verification

[`workload.json`](workload.json) includes both roots, asymmetric and near-boundary brackets, and invalid endpoint/sign cases. The verifier checks all nine ports on 966 cases, including a grid of valid brackets, deterministic random brackets, and malformed-domain pairs:

```sh
python3 benchmarks/verify_false_position.py
```

## Implementations

| Language | Source |
| --- | --- |
| C | [c/f/false_position.c](../../../c/f/false_position.c) |
| C3 | [c3/f/false_position.c3](../../../c3/f/false_position.c3) |
| C++ | [cpp/f/false_position.cpp](../../../cpp/f/false_position.cpp) |
| Elisa | [elisa/f/false_position.elisa](../../../elisa/f/false_position.elisa) |
| Nim | [nim/f/false_position.nim](../../../nim/f/false_position.nim) |
| Odin | [odin/f/false_position.odin](../../../odin/f/false_position.odin) |
| Rust | [rust/f/false_position.rs](../../../rust/f/false_position.rs) |
| V | [v/f/false_position.v](../../../v/f/false_position.v) |
| Zig | [zig/f/false_position.zig](../../../zig/f/false_position.zig) |

## TheAlgorithms references

- [C++ false_position.cpp](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/numerical_methods/false_position.cpp)
- [C++-Plus-Plus-1 false_position.cpp](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/numerical_methods/false_position.cpp)
- [MATLAB false_position.m](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/arithmetic_analysis/false_position.m)
