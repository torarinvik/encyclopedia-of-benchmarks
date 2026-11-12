# Largest zero submatrix

Given a bounded binary matrix, return the area of its largest axis-aligned
submatrix containing only zeros. A matrix with no zero cell has result zero.

## Contract

The `i64_array_scalar` symbol is `largest_zero_submatrix`. Input is
`[R,C,cells...]`, with `1<=R,C<=16`, row-major cells in `{0,1}`, and exact
length `2+R*C`. Maximum valid input length is 258 signed 64-bit values; 259
values are accepted by the parser only to reject trailing input. The result is
in `0..R*C`; malformed or out-of-profile input returns `-1`.

For each row, the primary algorithm updates the last row containing a one in
each column. It scans left and right with monotone stacks to find the nearest
column whose last-one row is strictly greater, then treats the current row as
the bottom of a zero rectangle. The best area for a column is
`(row-last_one[column]) * (right-left-1)`. The total work is `O(R*C)` with
`O(C)` auxiliary storage. The independent verifier enumerates every rectangle
and checks its cells directly, without using row heights or stack boundaries.

## Distinctness and provenance

[`largest_rectangle_histogram`](../largest_rectangle_histogram/README.md)
accepts one precomputed vector of bar heights and solves a one-dimensional
rectangle problem. This benchmark additionally updates nearest-one blockers
for each matrix row and searches over all possible top and bottom boundaries.
[`set_matrix_zeroes`](../set_matrix_zeroes/README.md) mutates rows and columns
containing zeros; it does not find a largest rectangle.

The algorithm description is from [CP-Algorithms, “Finding the largest zero
submatrix”](https://cp-algorithms.com/dynamic_programming/zero_matrix.html),
licensed CC BY-SA 4.0. The bounded contract, fixtures, independent exhaustive
oracle, and all ports are clean-room work. See [`RIGHTS.md`](RIGHTS.md),
[`workload.json`](workload.json), the [primary oracle](../../largest_zero_submatrix_oracle.py),
the [independent verifier](../../largest_zero_submatrix_verifier_oracle.py),
and the [static package checker](../../check_largest_zero_submatrix_package.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/l/largest_zero_submatrix.c`](../../../c/l/largest_zero_submatrix.c) |
| C3 | [`c3/l/largest_zero_submatrix.c3`](../../../c3/l/largest_zero_submatrix.c3) |
| C++ | [`cpp/l/largest_zero_submatrix.cpp`](../../../cpp/l/largest_zero_submatrix.cpp) |
| Elisa | [`elisa/l/largest_zero_submatrix.elisa`](../../../elisa/l/largest_zero_submatrix.elisa) |
| Mojo | [`mojo/l/largest_zero_submatrix.mojo`](../../../mojo/l/largest_zero_submatrix.mojo) |
| Nim | [`nim/l/largest_zero_submatrix.nim`](../../../nim/l/largest_zero_submatrix.nim) |
| Odin | [`odin/l/largest_zero_submatrix.odin`](../../../odin/l/largest_zero_submatrix.odin) |
| Rust | [`rust/l/largest_zero_submatrix.rs`](../../../rust/l/largest_zero_submatrix.rs) |
| V | [`v/l/largest_zero_submatrix.v`](../../../v/l/largest_zero_submatrix.v) |
| Zig | [`zig/l/largest_zero_submatrix.zig`](../../../zig/l/largest_zero_submatrix.zig) |
