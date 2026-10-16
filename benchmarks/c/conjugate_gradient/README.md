# Conjugate gradient

Solve the linear system `A x = b` for a symmetric positive-definite matrix with the conjugate-gradient recurrence. The ports begin with `x = 0`, residual `r = b`, and search direction `p = b`; they stop when the Euclidean residual norm is at most `1e-10`, or after 1,000 iterations.

## Contract

- The `i64_array_bytes_output` ABI input is `[n, A row-major in micro-units, b in micro-units]`. Both the matrix and vector are divided by 1,000,000 before solving; their shared scale cancels from the solution.
- `n` is 1 through 8. Every encoded matrix and vector entry is between -1,000,000,000 and 1,000,000,000.
- Matrices must be exactly symmetric, have positive diagonal entries, and be strictly row-diagonally dominant. This bounded domain guarantees positive definiteness using integer checks. The right-hand side may be zero. Invalid inputs return `-1`.
- The output is `n` little-endian IEEE-754 binary64 values. The function returns `8*n`; insufficient output capacity returns `-2`. Results are compared with the exact rational solution rounded to binary64, using absolute and relative tolerances of `1e-8`.

## Source semantics

The pinned [TheAlgorithms Python `conjugate_gradient.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/linear_algebra/src/conjugate_gradient.py) implements the standard `alpha` and `beta` updates and checks the matrix for positive definiteness. Its loop compares changes in the residual and solution to the tolerance rather than checking the residual norm; after an exact zero residual it can attempt another step with a zero denominator. The portable implementations keep the intended conjugate-gradient recurrence and use a residual-norm stop, including a direct zero-vector result for `b = 0`. The upstream Python repository is MIT licensed.

## Workload

[`workload.json`](workload.json) covers dimensions 1 through 6, signed off-diagonal entries, zero right-hand sides, malformed inputs, non-SPD matrices, and insufficient output capacity. The generic byte-output runner reads this workload and compares each result with the oracle.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/conjugate_gradient.c`](../../../c/c/conjugate_gradient.c) |
| C3 | [`c3/c/conjugate_gradient.c3`](../../../c3/c/conjugate_gradient.c3) |
| C++ | [`cpp/c/conjugate_gradient.cpp`](../../../cpp/c/conjugate_gradient.cpp) |
| Elisa | [`elisa/c/conjugate_gradient.elisa`](../../../elisa/c/conjugate_gradient.elisa) |
| Nim | [`nim/c/conjugate_gradient.nim`](../../../nim/c/conjugate_gradient.nim) |
| Odin | [`odin/c/conjugate_gradient.odin`](../../../odin/c/conjugate_gradient.odin) |
| Rust | [`rust/c/conjugate_gradient.rs`](../../../rust/c/conjugate_gradient.rs) |
| V | [`v/c/conjugate_gradient.v`](../../../v/c/conjugate_gradient.v) |
| Zig | [`zig/c/conjugate_gradient.zig`](../../../zig/c/conjugate_gradient.zig) |

Build a language with `python3 benchmarks/build_abi.py --algorithm conjugate_gradient --language LANGUAGE --family i64_array_bytes_output --output-dir build/conjugate_gradient-LANGUAGE`, then run `python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/conjugate_gradient-LANGUAGE/build.json`.
