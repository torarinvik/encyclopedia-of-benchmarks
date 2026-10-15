# Direct polynomial evaluation

This benchmark follows the pinned Python `evaluate_poly` routine, which evaluates each coefficient as `c_i * x**i` and sums terms in ascending degree order. It is separate from [`polynomial_evaluation`](../polynomial_evaluation/README.md), which benchmarks the same source file's Horner routine.

## Contract

- Input is `[coefficient_count, x, coefficient_0, ..., coefficient_(n-1)]`; coefficients are ordered by ascending degree.
- `coefficient_count` is 0..8, `x` is -10..10, and each coefficient is -1000..1000. Inputs use the exact integer-valued subset of the source's floating-point domain.
- Return `Σ coefficient_i * x^i`, with each power computed independently and terms accumulated in ascending degree order. An empty polynomial returns 0.
- Return `INT64_MIN` for malformed packing or values outside the stated bounds. Every valid result is below 2^53, so the source's binary64 value is exactly represented by the integer ABI.
- The ports use repeated multiplication to compute each direct power, preserving the direct-power method rather than Horner's recurrence.

The pinned source's example uses coefficient 9.3 and evaluates to 79,800 at x=10. This integer-only workload uses coefficient 9 instead, so its corresponding result is 79,500.

[`workload.json`](workload.json) covers empty, constant, sparse, positive and negative coefficient sets, and input boundaries.

| Language | Source |
| --- | --- |
| C | [`c/p/polynomial_evaluation_direct.c`](../../../c/p/polynomial_evaluation_direct.c) |
| C3 | [`c3/p/polynomial_evaluation_direct.c3`](../../../c3/p/polynomial_evaluation_direct.c3) |
| C++ | [`cpp/p/polynomial_evaluation_direct.cpp`](../../../cpp/p/polynomial_evaluation_direct.cpp) |
| Elisa | [`elisa/p/polynomial_evaluation_direct.elisa`](../../../elisa/p/polynomial_evaluation_direct.elisa) |
| Nim | [`nim/p/polynomial_evaluation_direct.nim`](../../../nim/p/polynomial_evaluation_direct.nim) |
| Odin | [`odin/p/polynomial_evaluation_direct.odin`](../../../odin/p/polynomial_evaluation_direct.odin) |
| Rust | [`rust/p/polynomial_evaluation_direct.rs`](../../../rust/p/polynomial_evaluation_direct.rs) |
| V | [`v/p/polynomial_evaluation_direct.v`](../../../v/p/polynomial_evaluation_direct.v) |
| Zig | [`zig/p/polynomial_evaluation_direct.zig`](../../../zig/p/polynomial_evaluation_direct.zig) |

Pinned source: [TheAlgorithms/Python `polynomial_evaluation.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/polynomial_evaluation.py).
