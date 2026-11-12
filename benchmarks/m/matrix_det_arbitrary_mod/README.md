# Determinant modulo an arbitrary integer

Compute the determinant of a square matrix modulo a possibly composite
modulus. The ports use Euclidean row transformations: for each pivot column,
they combine pairs of rows with unimodular transformations until the entries
below the pivot are zero. This avoids dividing by a pivot, which is not always
invertible modulo a composite number. Row swaps track the determinant sign.

## Contract

Input is `[N, M, row-major N-by-N matrix...]`, with `0 <= N <= 8`,
`2 <= M <= 1,000,000,000`, and every entry in `[0,M)`. The empty matrix has
determinant one. The result is the least nonnegative residue modulo `M`,
written as one signed 64-bit little-endian word. Invalid input returns `-1`;
null or short output returns `-2` without writing. The local input bound is
smaller than the official maximum `N=500`.

## Algorithm and distinctness

For each column, Euclidean quotient steps construct a 2-by-2 integer
transformation with determinant `+1` or `-1` that replaces two entries by
their gcd and zero. The transformation is applied modulo `M` to the matching
rows, preserving the determinant up to tracked row swaps. The bounded ports
run in `O(N^3 log M)` arithmetic operations with `O(N^2)` matrix storage.

The local [`determinant`](../../d/determinant/README.md) package uses recursive
cofactor expansion; prime-field determinant kernels can invert any nonzero
pivot. This profile supports composite moduli and uses Euclidean row
transformations instead. Its independent oracle computes the exact integer
determinant by cofactor expansion before reducing modulo `M`.

The algorithm idea is documented by the [Library Checker task](https://github.com/yosupo06/library-checker-problems/blob/master/linear_algebra/matrix_det_arbitrary_mod/task.md),
its [official limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/linear_algebra/matrix_det_arbitrary_mod/info.toml),
and the [upstream Euclidean-elimination solution](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/linear_algebra/matrix_det_arbitrary_mod/sol/correct.cpp).
The repository is [Apache-2.0 licensed](https://github.com/yosupo06/library-checker-problems/blob/master/LICENSE); this package uses the task
contract and algorithm idea in clean-room implementations, without copying its
source code.

[`workload.json`](workload.json) covers the empty matrix, modular sign, a
non-unit pivot over a composite modulus, a determinant divisible by the
modulus, singular matrices, malformed inputs, and output-buffer behavior.

## Implementations

| Language | Port |
|---|---|
| C | [`c/m/matrix_det_arbitrary_mod.c`](../../../c/m/matrix_det_arbitrary_mod.c) |
| C3 | [`c3/m/matrix_det_arbitrary_mod.c3`](../../../c3/m/matrix_det_arbitrary_mod.c3) |
| C++ | [`cpp/m/matrix_det_arbitrary_mod.cpp`](../../../cpp/m/matrix_det_arbitrary_mod.cpp) |
| Elisa | [`elisa/m/matrix_det_arbitrary_mod.elisa`](../../../elisa/m/matrix_det_arbitrary_mod.elisa) |
| Mojo | [`mojo/m/matrix_det_arbitrary_mod.mojo`](../../../mojo/m/matrix_det_arbitrary_mod.mojo) |
| Nim | [`nim/m/matrix_det_arbitrary_mod.nim`](../../../nim/m/matrix_det_arbitrary_mod.nim) |
| Odin | [`odin/m/matrix_det_arbitrary_mod.odin`](../../../odin/m/matrix_det_arbitrary_mod.odin) |
| Rust | [`rust/m/matrix_det_arbitrary_mod.rs`](../../../rust/m/matrix_det_arbitrary_mod.rs) |
| V | [`v/m/matrix_det_arbitrary_mod.v`](../../../v/m/matrix_det_arbitrary_mod.v) |
| Zig | [`zig/m/matrix_det_arbitrary_mod.zig`](../../../zig/m/matrix_det_arbitrary_mod.zig) |
