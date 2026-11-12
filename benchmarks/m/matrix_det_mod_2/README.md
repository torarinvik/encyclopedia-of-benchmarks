# Determinant modulo two

Compute the determinant of a square binary matrix over `GF(2)`. Rows are
packed into 64-bit words and eliminated using XOR. Since `-1 = 1` in this
field, row swaps do not change the determinant; the determinant is one exactly
when elimination finds a pivot in every column.

## Contract

Input is `[N, row-major N-by-N matrix...]`, with `1 <= N <= 64` and every
entry equal to 0 or 1. Output is one signed 64-bit little-endian residue,
either zero or one. Invalid input returns `-1`; null or short output returns
`-2` without writing. The local bound is smaller than the official maximum of
4096.

The ports perform packed Gaussian elimination in `O(N^2)` word operations
using `O(N)` words. A packed word stores each row; a pivot row is XORed into
rows below when they contain the pivot bit.

## Distinctness and provenance

The local [`determinant`](../../d/determinant/README.md) benchmark uses
recursive cofactor expansion, while the generic `matrix_rank` profile operates
over real values. This task uses bit-packed finite-field elimination, where
addition is XOR, so it measures a distinct arithmetic representation and
kernel.

Official contract: [Library Checker — Determinant of Matrix (Mod 2)](https://github.com/yosupo06/library-checker-problems/blob/master/linear_algebra/matrix_det_mod_2/task.md)
and its [limits](https://github.com/yosupo06/library-checker-problems/blob/master/linear_algebra/matrix_det_mod_2/info.toml).
Implementations are clean-room ports of the high-level operation.

[`workload.json`](workload.json) covers invertible, singular, permuted,
triangular, malformed, and output-buffer cases. The oracle uses scalar Boolean
row elimination instead of packed words.

## Implementations

| Language | Port |
|---|---|
| C | [`c/m/matrix_det_mod_2.c`](../../../c/matrix_det_mod_2.c) |
| C3 | [`c3/m/matrix_det_mod_2.c3`](../../../c3/m/matrix_det_mod_2.c3) |
| C++ | [`cpp/m/matrix_det_mod_2.cpp`](../../../cpp/matrix_det_mod_2.cpp) |
| Elisa | [`elisa/m/matrix_det_mod_2.elisa`](../../../elisa/m/matrix_det_mod_2.elisa) |
| Nim | [`nim/m/matrix_det_mod_2.nim`](../../../nim/matrix_det_mod_2.nim) |
| Odin | [`odin/m/matrix_det_mod_2.odin`](../../../odin/m/matrix_det_mod_2.odin) |
| Rust | [`rust/m/matrix_det_mod_2.rs`](../../../rust/m/matrix_det_mod_2.rs) |
| V | [`v/m/matrix_det_mod_2.v`](../../../v/m/matrix_det_mod_2.v) |
| Zig | [`zig/m/matrix_det_mod_2.zig`](../../../zig/m/matrix_det_mod_2.zig) |
| Mojo | [`mojo/m/matrix_det_mod_2.mojo`](../../../mojo/m/matrix_det_mod_2.mojo) |
