# Sparse matrix determinant over a prime field

Compute the determinant of a sparse square matrix modulo `998244353`. The
ports use sparse matrix-vector products inside seeded Wiedemann/Krylov
projections, recover a scalar recurrence with Berlekamp–Massey, and derive the
determinant when the recovered recurrence has full degree. A fixed number of
projection attempts keeps the work bounded. If none reveals the full
characteristic polynomial, a small dense modular Gaussian elimination
fallback guarantees the exact answer for every accepted input.

## Contract

Input is `[N, K, (row, column, value)*K]`, with `1 <= N <= 8` and
`1 <= K <= 64`. Coordinates are zero-based, in range, and distinct. Each
stored value is in `1..998244352`; omitted cells are zero. The result is the
least nonnegative determinant residue modulo `998244353`, encoded as one
signed 64-bit little-endian word. Invalid input returns `-1`. A null or short
output buffer returns `-2` without writing. The largest valid input has 194
values; 195 values are parseable for malformed-length handling.

This is a bounded local profile of the [Library Checker sparse determinant
task](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/linear_algebra/sparse_matrix_det/task.md),
whose official limits are `N <= 3000`, `K <= 10000`, and the same prime
modulus. The local size keeps the deterministic fallback inexpensive while
still exercising the sparse projection and recurrence-recovery path.

## Algorithm and exactness

For each of at most four attempts, a reproducible modular generator chooses a
nonzero diagonal scaling `D` and left/right projection vectors. The code
forms `2N` terms of the sequence `lᵀ(AD)^i r` using only the stored entries,
then applies Berlekamp–Massey. When its connection polynomial has degree `N`,
that polynomial is the characteristic polynomial of `AD`; its constant term
gives `det(A) * det(D)` up to the sign `(-1)^N`. Since every diagonal entry
of `D` is nonzero, the scale is invertible.

Projection vectors can fail to expose the full polynomial, and the projection
method is probabilistic. The implementation never treats a lower-degree
recurrence as an answer: after four unsuccessful attempts it constructs the
bounded dense matrix and computes its determinant by modular elimination.
Thus the seed and retry count affect performance only, not the returned
determinant. The workload oracle uses recursive cofactor expansion, an
independent method suited to these small matrices.

The official task limits are in
[`info.toml`](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/linear_algebra/sparse_matrix_det/info.toml).
The reference algorithm is described by the upstream
[`correct.cpp`](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/linear_algebra/sparse_matrix_det/sol/correct.cpp);
these ports are clean-room implementations of the algorithm idea.

See [`workload.json`](workload.json) and the independent
[`benchmarks/sparse_matrix_det_oracle.py`](../../sparse_matrix_det_oracle.py).

## Implementations

| Language | Port |
|---|---|
| C | [`c/s/sparse_matrix_det.c`](../../../c/s/sparse_matrix_det.c) |
| C3 | [`c3/s/sparse_matrix_det.c3`](../../../c3/s/sparse_matrix_det.c3) |
| C++ | [`cpp/s/sparse_matrix_det.cpp`](../../../cpp/s/sparse_matrix_det.cpp) |
| Elisa | [`elisa/s/sparse_matrix_det.elisa`](../../../elisa/s/sparse_matrix_det.elisa) |
| Mojo | [`mojo/s/sparse_matrix_det.mojo`](../../../mojo/s/sparse_matrix_det.mojo) |
| Nim | [`nim/s/sparse_matrix_det.nim`](../../../nim/s/sparse_matrix_det.nim) |
| Odin | [`odin/s/sparse_matrix_det.odin`](../../../odin/s/sparse_matrix_det.odin) |
| Rust | [`rust/s/sparse_matrix_det.rs`](../../../rust/s/sparse_matrix_det.rs) |
| V | [`v/s/sparse_matrix_det.v`](../../../v/s/sparse_matrix_det.v) |
| Zig | [`zig/s/sparse_matrix_det.zig`](../../../zig/s/sparse_matrix_det.zig) |
