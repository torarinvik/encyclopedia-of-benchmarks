# Characteristic polynomial over a prime field

Compute the characteristic polynomial `det(xI-A)` of a square matrix over
`Z/998244353Z`. The ports reduce the matrix by similarity transformations to
upper Hessenberg form, then use the leading-principal-submatrix recurrence to
recover every coefficient. Coefficients are returned in ascending degree
order, from the constant term through the monic term.

## Contract

Input is `[N, row-major N-by-N matrix...]`, with `0 <= N <= 8` locally and
each entry in `[0, 998244353)`. The official task allows `N <= 500`. The empty
matrix has characteristic polynomial `1`. Output is `N+1` signed 64-bit
little-endian residues, requiring `8*(N+1)` bytes. Invalid input returns `-1`;
null output or insufficient capacity returns `-2` without writing.

## Algorithm and distinctness

For each column below the first subdiagonal, pivoting and paired row/column
operations perform a similarity transform while eliminating entries below
the first subdiagonal. For the resulting upper Hessenberg matrix, the
characteristic polynomial of each leading principal submatrix follows from
the preceding one and products of its subdiagonal entries. The local bound
keeps the arithmetic and fixed-size storage small.

This returns the full polynomial. The local determinant packages return only
a scalar, and `similar_matrices` returns an equivalence decision, so neither
has the same benchmark contract. The independent oracle expands the
determinant of `xI-A` over permutations, rather than using Hessenberg
reduction.

The official contract is [Library Checker — Characteristic Polynomial](https://github.com/yosupo06/library-checker-problems/blob/master/linear_algebra/characteristic_polynomial/task.md),
with [limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/linear_algebra/characteristic_polynomial/info.toml)
and the [reference method](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/linear_algebra/characteristic_polynomial/sol/correct.cpp).
Implementations here are clean-room ports of the high-level algorithm.

[`workload.json`](workload.json) covers empty and small matrices, a pivoting
case, the maximum local dimension, malformed input, and output-buffer
behavior.

## Implementations

| Language | Port |
|---|---|
| C | [`c/m/characteristic_polynomial.c`](../../../c/m/characteristic_polynomial.c) |
| C3 | [`c3/m/characteristic_polynomial.c3`](../../../c3/m/characteristic_polynomial.c3) |
| C++ | [`cpp/m/characteristic_polynomial.cpp`](../../../cpp/m/characteristic_polynomial.cpp) |
| Elisa | [`elisa/m/characteristic_polynomial.elisa`](../../../elisa/m/characteristic_polynomial.elisa) |
| Mojo | [`mojo/m/characteristic_polynomial.mojo`](../../../mojo/m/characteristic_polynomial.mojo) |
| Nim | [`nim/m/characteristic_polynomial.nim`](../../../nim/m/characteristic_polynomial.nim) |
| Odin | [`odin/m/characteristic_polynomial.odin`](../../../odin/m/characteristic_polynomial.odin) |
| Rust | [`rust/m/characteristic_polynomial.rs`](../../../rust/m/characteristic_polynomial.rs) |
| V | [`v/m/characteristic_polynomial.v`](../../../v/m/characteristic_polynomial.v) |
| Zig | [`zig/m/characteristic_polynomial.zig`](../../../zig/m/characteristic_polynomial.zig) |
