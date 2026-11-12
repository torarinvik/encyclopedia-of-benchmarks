# NPB sparse CG inverse-power kernel

This package is a bounded, clean-room core profile of the NAS Parallel
Benchmarks Conjugate Gradient kernel. It retains the coupled workload from
NASA's pencil-and-paper definition: a sparse SPD matrix is used by the
matrix-vector products of repeated CG solves, and an outer inverse-power loop
updates the eigenvalue estimate and starting vector.

It is distinct from the local [`conjugate_gradient`](../../c/conjugate_gradient/README.md)
package. That package solves one dense row-major system `A x = b`. This one
stores `A` in CSR form, begins with an all-ones vector, solves `A z = x` inside
each outer iteration, reports the estimate `shift + 1/(x^T z)` and an explicitly
computed residual norm, then normalizes `z` for the next iteration.

## Bounded contract

The `i64_array_bytes_output` entry point is
`npb_cg_sparse_inverse_power(values, length, output, output_capacity)`. Input is
`[n, outer_iterations, cg_steps, shift_micro, nnz, row_ptr[n+1],
column_index[nnz], value_micro[nnz]]`. Dimensions are 1 through 32, outer
iterations are 1 through 8, and each inner solve performs at most
`min(25,n)` CG steps. The input values use a scale of 1,000,000. CSR rows must
have sorted unique columns and nonzero entries. The matrix must be exactly
symmetric with positive diagonals that strictly dominate the sum of the
absolute off-diagonal entries in each row; this integer check certifies SPD.
The shift and matrix entries are bounded to ±1,000,000,000 micro-units.

Each inner solve starts with `z=0`, `r=x`, and `p=r`. It uses the standard CG
updates for at most the caller-selected step count and stops early when the
recursive residual norm is at most 1e-14 times its initial norm. The returned
residual is recomputed from `x-Az` after the solve. Output contains two binary64
values per outer iteration: the eigenvalue estimate and this explicit residual
norm. Success returns the output byte length; malformed inputs return `-1`,
and a null or undersized output buffer returns `-2`.

The local profile takes the explicit sparse matrix as input rather than
recreating NASA's `makea` random outer-product generator. It also caps the
matrix and iteration counts for a portable single-call workload. It therefore
claims the sparse matrix-vector plus inverse-power/CG core, not a canonical
NPB class run or NPB's full matrix-generation cost.

The primary oracle follows the sparse representation. The independent verifier
materializes a dense matrix and checks the same bounded iteration profile with
a separate dense matrix-vector path. Both use an absolute and relative output
tolerance of 1e-8. The static package checker validates fixtures, bounds,
provenance, and all listed ports without running benchmark programs.

## Provenance

The specification is D. Bailey et al., [*The NAS Parallel Benchmarks*, NASA
Ames NAS Technical Report RNR-94-007](https://www.nas.nasa.gov/assets/nas/pdf/techreports/1994/rnr-94-007.pdf),
March 1994, §2.2.3. That section specifies sparse matrix-vector products,
conjugate-gradient inner solves, the inverse-power outer update, and the
residual/eigenvalue verification values.

See [`RIGHTS.md`](RIGHTS.md) for the clean-room provenance note and
[`workload.json`](workload.json) for fixtures and machine-readable bounds.

## Implementations

| Language | Source |
|---|---|
| C | [`c/n/npb_cg_sparse_inverse_power.c`](../../../c/n/npb_cg_sparse_inverse_power.c) |
| C3 | [`c3/n/npb_cg_sparse_inverse_power.c3`](../../../c3/n/npb_cg_sparse_inverse_power.c3) |
| C++ | [`cpp/n/npb_cg_sparse_inverse_power.cpp`](../../../cpp/n/npb_cg_sparse_inverse_power.cpp) |
| Elisa | [`elisa/n/npb_cg_sparse_inverse_power.elisa`](../../../elisa/n/npb_cg_sparse_inverse_power.elisa) |
| Mojo | [`mojo/n/npb_cg_sparse_inverse_power.mojo`](../../../mojo/n/npb_cg_sparse_inverse_power.mojo) |
| Nim | [`nim/n/npb_cg_sparse_inverse_power.nim`](../../../nim/n/npb_cg_sparse_inverse_power.nim) |
| Odin | [`odin/n/npb_cg_sparse_inverse_power.odin`](../../../odin/n/npb_cg_sparse_inverse_power.odin) |
| Rust | [`rust/n/npb_cg_sparse_inverse_power.rs`](../../../rust/n/npb_cg_sparse_inverse_power.rs) |
| V | [`v/n/npb_cg_sparse_inverse_power.v`](../../../v/n/npb_cg_sparse_inverse_power.v) |
| Zig | [`zig/n/npb_cg_sparse_inverse_power.zig`](../../../zig/n/npb_cg_sparse_inverse_power.zig) |

