# System of Linear Equations Modulo Two

This benchmark solves `A x = b` over the two-element field GF(2). It follows
the problem contract in [Library Checker: System of Linear Equations Mod 2](https://github.com/yosupo06/library-checker-problems/tree/master/linear_algebra/system_of_linear_equations_mod_2)
and the stated [problem limits](https://github.com/yosupo06/library-checker-problems/blob/master/linear_algebra/system_of_linear_equations_mod_2/info.toml).
Those references provide the mathematical problem and contract only. The
benchmark implementations and oracle are clean-room code.

## Contract

Input is `[N, M, A_0_0, ..., A_(N-1)_(M-1), b_0, ..., b_(N-1)]`, with
`1 <= N, M <= 32` and all matrix and right-hand-side entries in `{0, 1}`.
The matrix is row-major. A consistent system returns little-endian unsigned
64-bit words `[R, x, v_0, ..., v_(R-1)]`: `R` is the nullity, `x` is one
particular solution, and the `v` words are a basis for the homogeneous
solution space. Bit `j` in a word is component `j`; basis vectors are ordered
by increasing free-column index. The particular solution sets all free
variables to zero. An inconsistent system returns one all-ones 64-bit word.

Invalid input returns `-1`. Null output or insufficient capacity returns
`-2`; error paths leave output untouched. The maximum parseable input has
1,058 signed 64-bit values. The maximum output is 272 bytes. Each package
uses at most 1,024 bytes of declared bounded workspace.

## Algorithm

Each port packs every coefficient row into one 64-bit word and stores its
right-hand-side bit separately. It scans columns left to right, swaps in a
pivot row, then XOR-eliminates that column from every other row to produce
reduced row-echelon form. A zero coefficient row with right-hand side one is
inconsistent. The pivot rows produce the particular solution; each free
column yields one nullspace basis vector. The bounded cost is
`O(N*M*min(N,M))` bit operations and `O(N)` packed words of working storage.

The separate Python oracle performs scalar Boolean row operations instead of
the ports' packed-word elimination. See [`workload.json`](workload.json) for
the deterministic fixtures and error cases.

## Distinction from determinant benchmarks

The existing `matrix_det_mod_2` package reports only whether a square matrix
has full rank. This package accepts rectangular systems with a right-hand
side and returns a particular solution plus a basis for every solution. It
therefore has a distinct input/output contract and computational result.

## Language ports

| Language | Source |
|---|---|
| C | [`c/s/system_of_linear_equations_mod_2.c`](../../../c/s/system_of_linear_equations_mod_2.c) |
| C3 | [`c3/s/system_of_linear_equations_mod_2.c3`](../../../c3/s/system_of_linear_equations_mod_2.c3) |
| C++ | [`cpp/s/system_of_linear_equations_mod_2.cpp`](../../../cpp/s/system_of_linear_equations_mod_2.cpp) |
| Elisa | [`elisa/s/system_of_linear_equations_mod_2.elisa`](../../../elisa/s/system_of_linear_equations_mod_2.elisa) |
| Mojo | [`mojo/s/system_of_linear_equations_mod_2.mojo`](../../../mojo/s/system_of_linear_equations_mod_2.mojo) |
| Nim | [`nim/s/system_of_linear_equations_mod_2.nim`](../../../nim/s/system_of_linear_equations_mod_2.nim) |
| Odin | [`odin/s/system_of_linear_equations_mod_2.odin`](../../../odin/s/system_of_linear_equations_mod_2.odin) |
| Rust | [`rust/s/system_of_linear_equations_mod_2.rs`](../../../rust/s/system_of_linear_equations_mod_2.rs) |
| V | [`v/s/system_of_linear_equations_mod_2.v`](../../../v/s/system_of_linear_equations_mod_2.v) |
| Zig | [`zig/s/system_of_linear_equations_mod_2.zig`](../../../zig/s/system_of_linear_equations_mod_2.zig) |
