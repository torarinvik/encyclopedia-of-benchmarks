# Thiele rational interpolation

This package evaluates Thiele's reciprocal-difference continued fraction through an ordered set of sample pairs. The local catalogue's Newton divided-difference and polynomial interpolation packages compute polynomial interpolants; this package is a distinct rational interpolation construction.

The frame is `[N, x_0, y_0, ..., x_(N-1), y_(N-1), q]`, with `1 <= N <= 6`. Every numeric field is finite binary64 in `[-8, 8]` and must be an exact multiple of `2^-54`; only `N` must be integer-valued. Nodes are separated by at least `1/16`, and their order is significant. A successful call writes one binary64 value. Malformed, degenerate, nonfinite, or guarded-pole cases return `-1`; a valid request with a null or undersized output returns `-2` and writes nothing. Input validity and interpolation are checked before output-buffer validity.

For `N` samples, the prescribed rational type uses `deg(P) <= floor(N/2)` and `deg(Q) <= floor((N-1)/2)`, equivalent to `(ceil((N-1)/2), floor((N-1)/2))`. The homogeneous coefficients in `P(x_i) - y_i Q(x_i) = 0` are defined only up to a common nonzero scale. The independent oracle fixes its first free coefficient to one and solves/evaluates that rational type with exact fractions when the coefficient matrix has rank `N` and the evaluation is finite. It falls back to its guarded binary64 evaluation if exact rank or pole conditions do not yield a unique result, so those exact checks never add a status precondition. The ports define validity through the complete guarded binary64 inverse-difference table and continued-fraction evaluation. They accept inverse-difference denominators, diagonal coefficients, and tails only when their magnitudes are strictly between `1/32 + 2^-32` and `64 - 2^-32`; all other table intermediates and results must be finite and strictly below the upper cap in magnitude. Near-poles in the lower guard band are invalid. A query exactly equal to a sample node returns its `y_i` after the table checks succeed. Constant two-point data are rejected because the first Thiele inverse difference is undefined, even though the prescribed rational type itself can still be unique.

The primary method follows Stoer and Bulirsch, *Introduction to Numerical Analysis*, 3rd ed., §2.2.2 ([textbook copy](https://www.math.kent.edu/~reichel/courses/numerical.analysis.2/Numerical-book.pdf)). The independent oracle uses an exact rational homogeneous linear system for the same degree pair, based on the formulation discussed by Levrie and Bultheel, [“A Note on Thiele n-Fractions”](https://doi.org/10.1007/BF02144105); it uses the guarded binary64 result only when that exact system is singular or has a pole. The [RosettaGit task-title index](https://rosettagit.org/tasks/) was used only to discover the title; no task statement, examples, tests, submissions, or code were used.

The workload pins fractional dyadic sample values and queries, all sample counts, node lookup, repeated nodes, non-unique linear data, constant two-point method degeneracy, an exact pole, a near-pole at the lower threshold, a denominator at the guard boundary, malformed frames, and the C ABI null/capacity boundary. Output comparison uses absolute tolerance `1e-5` and relative tolerance `1e-6`.

## Ports

- C: [source](../../../c/t/thiele_rational_interpolation.c)
- C3: [source](../../../c3/t/thiele_rational_interpolation.c3)
- C++: [source](../../../cpp/t/thiele_rational_interpolation.cpp)
- Elisa: [source](../../../elisa/t/thiele_rational_interpolation.elisa)
- Mojo: [source](../../../mojo/t/thiele_rational_interpolation.mojo)
- Nim: [source](../../../nim/t/thiele_rational_interpolation.nim)
- Odin: [source](../../../odin/t/thiele_rational_interpolation.odin)
- Rust: [source](../../../rust/t/thiele_rational_interpolation.rs)
- V: [source](../../../v/t/thiele_rational_interpolation.v)
- Zig: [source](../../../zig/t/thiele_rational_interpolation.zig)

The package contains a binary64 primary oracle, an independently structured exact-rational oracle, workload validation, and a static source/provenance inventory. No executable checks were run while drafting these files.
