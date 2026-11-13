# Blocked right-looking LU factorization

This benchmark measures a bounded serial blocked LU kernel with a fixed tile width of two. The input matrices are strictly row-diagonally-dominant with positive diagonal entries, so the no-pivot factorization has nonzero pivots. The result is the ordinary mathematical LU factorization; the distinct benchmark operation is its blocked data movement and update schedule.

## Contract

The exported `float64_slice_io` symbol is `blocked_lu_factorization`. Input is `[N, A[0,0], A[0,1], ...]`, where `A` is a row-major `N×N` matrix. `N` must be even and in `2..=8`. Every matrix entry must be an exact integer in binary64: diagonal entries are `1..=16`, off-diagonal entries are `-2..=2`, and each row must satisfy `A[i,i] > sum(j != i, abs(A[i,j]))`.

The primary kernel processes diagonal tiles in increasing order. It factors each 2×2 diagonal tile, solves the corresponding block row and block column, then updates each remaining tile with the rank-two Schur update. The diagonal tile uses scalar no-pivot elimination; the block row is solved against its unit-lower diagonal factor, and the block column is solved against its upper factor. Inner tile products are accumulated in increasing index order. The implementation is serial: processor assignment, barriers, and a parallel schedule are outside this ABI.

Output is the full row-major lower factor `L`, followed by full row-major upper factor `U`, with `L[i,i]=1` and zeros outside each factor's triangle. Success returns `2*N*N` elements. Malformed framing, invalid ranges, a row that is not strictly diagonally dominant, a zero/nonfinite pivot, or nonfinite factors returns `-1`. A null output or capacity below `2*N*N` returns `-2` without writing output. Input and factor validity take precedence over output-buffer errors. Maximum valid input length is 65 float64 values; maximum parseable length is 66. Maximum output is 128 float64 values (1024 bytes). The fixed workspace budget is 2560 bytes, including the packed Schur matrix, L, U, and staged output. Tolerances are absolute and relative `1e-10`.

The algorithm is O(N³) time and O(N²) storage. The block width remains two for every input size, including the maximum N=8 profile.

## Distinctness and provenance

Local [`lu_decompose`](../../l/lu_decompose/README.md) and [`lu_pivot_decomposition`](../../l/lu_pivot_decomposition/README.md) use scalar row-wise elimination, while [`linpack_lu_solve`](../../l/linpack_lu_solve/README.md) consumes already supplied factors. This benchmark uses a blocked panel/diagonal-tile schedule and trailing-tile updates. It returns the same mathematical L and U factors as ordinary LU, but exposes a different data movement and update profile.

The SPLASH-2 characterization motivates block partitioning for locality and uses no pivoting. Its historical update schedule uses BLAS-1 row updates, so this package is not described as a reproduction of that exact kernel. The bounded serial blocked right-looking variant is specified from the general blocked-LU equations in the FLAME material. Only clean-room algorithm descriptions are used; no upstream implementation or benchmark samples are copied.

- SPLASH-2 characterization, DOI [10.1145/223982.223990](https://doi.org/10.1145/223982.223990).
- FLAME, [Blocked right-looking LU factorization](https://www.cs.utexas.edu/~flame/laff/alaff/chapter05-blocked-lu-factorization.html).

## Artifacts

- Workload and ABI fixtures: [`workload.json`](workload.json)
- Primary blocked oracle: [`blocked_lu_factorization_oracle.py`](../../blocked_lu_factorization_oracle.py)
- Independent scalar Doolittle oracle: [`blocked_lu_factorization_verifier_oracle.py`](../../blocked_lu_factorization_verifier_oracle.py)
- Static source/workload inventory: [`check_inventory.py`](check_inventory.py)

## Ports

| Language | Source |
| --- | --- |
| C | [`c/b/blocked_lu_factorization.c`](../../../c/b/blocked_lu_factorization.c) |
| C3 | [`c3/b/blocked_lu_factorization.c3`](../../../c3/b/blocked_lu_factorization.c3) |
| C++ | [`cpp/b/blocked_lu_factorization.cpp`](../../../cpp/b/blocked_lu_factorization.cpp) |
| Elisa | [`elisa/b/blocked_lu_factorization.elisa`](../../../elisa/b/blocked_lu_factorization.elisa) |
| Mojo | [`mojo/b/blocked_lu_factorization.mojo`](../../../mojo/b/blocked_lu_factorization.mojo) |
| Nim | [`nim/b/blocked_lu_factorization.nim`](../../../nim/b/blocked_lu_factorization.nim) |
| Odin | [`odin/b/blocked_lu_factorization.odin`](../../../odin/b/blocked_lu_factorization.odin) |
| Rust | [`rust/b/blocked_lu_factorization.rs`](../../../rust/b/blocked_lu_factorization.rs) |
| V | [`v/b/blocked_lu_factorization.v`](../../../v/b/blocked_lu_factorization.v) |
| Zig | [`zig/b/blocked_lu_factorization.zig`](../../../zig/b/blocked_lu_factorization.zig) |
