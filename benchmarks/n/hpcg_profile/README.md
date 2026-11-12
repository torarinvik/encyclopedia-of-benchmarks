# Bounded HPCG PCG profile

This package implements a small, deterministic single-process profile of the
coupled HPCG computation. The official project describes HPCG as fixed-count
double-precision multigrid-preconditioned conjugate gradients using a
symmetric Gauss–Seidel smoother; its overview names sparse matrix-vector
products, vector updates, dot products, local symmetric Gauss–Seidel, and
nested coarse grids ([HPCG 3.1 repository README](https://github.com/hpcg-benchmark/hpcg/blob/master/README.md),
[official overview](https://www.hpcg-benchmark.org/index.html)).

## Bounded contract

ABI: `i64_array_bytes_output`; symbol: `hpcg_profile`.

Input is `[n, cg_steps, nnz, row_ptr[n+1], column_index[nnz],
value_micro[nnz], rhs_micro[n]]`. `n` is 1 through 32, `cg_steps` is 1
through `min(12,n)`, and each CSR row has at most six nonzeros. Values and
right-hand-side entries are signed integers scaled by 1,000,000. CSR rows have
strictly increasing columns and nonzero values. The matrix must be exactly
symmetric; each row has a positive diagonal strictly greater than the sum of
its off-diagonal magnitudes, which certifies positive definiteness. Input is
limited to 452 signed 64-bit words.

Each coarse-grid variable aggregates two consecutive fine variables:
`P[i,k]=1` when `k=floor(i/2)`, otherwise zero. A preconditioner application
starts with a forward sparse Gauss–Seidel pre-sweep from zero, restricts the
resulting residual with `Pᵀ`, solves the assembled coarse system
`(Pᵀ A P)e=Pᵀr`, and prolongs `Pe`. It then recomputes the residual and applies
a backward sparse Gauss–Seidel post-sweep. Preconditioned CG starts from zero,
runs at most the supplied number of iterations, and stops early when its
recursive residual norm is at most `1e-14` times its initial norm. Every
matrix-vector product uses the input CSR representation.

Output is `n` binary64 solution values followed by the explicitly recomputed
Euclidean residual norm `||b-Ax||`, in little-endian byte order. Success
returns `8*(n+1)`. Malformed input returns `-1`; a null or undersized output
buffer returns `-2`. Floating outputs use absolute and relative tolerances of
`1e-8`.

This bounded local profile supplies the matrix and right-hand side, uses one
aggregate-pair coarse level, and caps the solve at 12 iterations. The
two-level V-cycle and consecutive-pair aggregation are profile choices. It omits
HPCG's problem generation, nested hierarchy beyond that one coarse level,
distributed MPI communication, OpenMP execution, official memory-scale and
runtime rules, and performance tuning. It is an algorithmic coupled-workload
profile, not an official HPCG implementation or result.

The sparse primary oracle and dense independent oracle are included beside
this README. [`workload.json`](workload.json) gives the fixtures and bounds;
[`verify_workload.py`](verify_workload.py) is a static package checker and is
not part of benchmark execution.

## Rights and provenance

The ports are clean-room implementations based on the published HPCG
algorithm descriptions. No upstream source implementation, comments, or
reference code were copied. See [`RIGHTS.md`](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [`c/n/hpcg_profile.c`](../../../c/n/hpcg_profile.c) |
| C3 | [`c3/n/hpcg_profile.c3`](../../../c3/n/hpcg_profile.c3) |
| C++ | [`cpp/n/hpcg_profile.cpp`](../../../cpp/n/hpcg_profile.cpp) |
| Elisa | [`elisa/n/hpcg_profile.elisa`](../../../elisa/n/hpcg_profile.elisa) |
| Mojo | [`mojo/n/hpcg_profile.mojo`](../../../mojo/n/hpcg_profile.mojo) |
| Nim | [`nim/n/hpcg_profile.nim`](../../../nim/n/hpcg_profile.nim) |
| Odin | [`odin/n/hpcg_profile.odin`](../../../odin/n/hpcg_profile.odin) |
| Rust | [`rust/n/hpcg_profile.rs`](../../../rust/n/hpcg_profile.rs) |
| V | [`v/n/hpcg_profile.v`](../../../v/n/hpcg_profile.v) |
| Zig | [`zig/n/hpcg_profile.zig`](../../../zig/n/hpcg_profile.zig) |
