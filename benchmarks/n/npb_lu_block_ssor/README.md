# NPB LU block SSOR core

This package captures a bounded part of the NAS Parallel Benchmarks LU solver:
the regular seven-block-diagonal operator and one or more point SSOR sweeps.
NASA orders unknowns lexicographically on a 3-D grid, with a 5×5 block at each
grid point, and describes lower and upper regular sparse block solves followed
by an update. The local profile keeps that five-component, seven-block data
flow and accepts the operator, right-hand side, and initial state directly.

It is distinct from the local LU decomposition and solve packages, which perform
direct dense matrix factorization, and from the scalar Gauss–Seidel and
red/black relaxation packages, which do not execute this 3-D block triangular
SSOR pair. The profile does not claim the full CFD application: it omits the
PDE-derived coefficients, forcing and boundary construction, and full NPB time
step schedule. Its directional neighbor blocks are restricted to scalar
identity blocks, while the shared diagonal block remains a full symmetric 5×5
matrix.

## Bounded contract

The `i64_array_bytes_output` entry point is
`npb_lu_block_ssor(values, length, output, output_capacity)`. Input is
`[nx, ny, nz, sweeps, D[25], cx, cy, cz, rhs[5*points], initial_x[5*points]]`.
Dimensions are 1 through 4, the grid contains at most 32 points, and there are
1 through 8 sweeps. Matrix and vector coefficients are signed integer
micro-units with a scale of 1,000,000. `D` must be symmetric with positive
diagonal and strict row diagonal dominance after including active directional
couplings; this certifies the global symmetric matrix is positive definite.
Grid points use x-fastest lexicographic order and each point holds five
consecutive components.

Each sweep computes `r=b-Kx`, solves `(D+Y)y=r` in forward order, solves
`(D+Z)z=D y` in reverse order, updates `x=x+z` with `omega=1`, and explicitly
recomputes `||b-Kx||`. Output is the residual norm after each sweep followed by
the final component vector, all as little-endian binary64 values. Success
returns the byte count; malformed input returns `-1`; a null or undersized
output buffer returns `-2`.

The primary oracle uses the regular stencil directly. The independent verifier
materializes the full matrix and applies dense global solves. Both use absolute
and relative tolerances of 1e-8. The package-local static checker reviews
provenance, framing, fixtures, oracle agreement, and the ten source paths. It
does not launch the benchmark implementations.

## Provenance and rights

The source is D. Bailey et al., [*The NAS Parallel Benchmarks*, NASA Ames NAS
Technical Report RNR-94-007](https://www.nas.nasa.gov/assets/nas/pdf/techreports/1994/rnr-94-007.pdf),
March 1994, §3.3.2. Section 3.3.2 specifies the lexicographic 3-D block
operator and the symmetric SSOR iteration. The implementations are clean-room
translations of that algorithmic description, not copies of NASA sample code,
comments, prose, or reference output.

See [`RIGHTS.md`](RIGHTS.md) for the provenance note and
[`workload.json`](workload.json) for the machine-readable contract.

## Implementations

| Language | Source |
|---|---|
| C | [`c/n/npb_lu_block_ssor.c`](../../../c/n/npb_lu_block_ssor.c) |
| C3 | [`c3/n/npb_lu_block_ssor.c3`](../../../c3/n/npb_lu_block_ssor.c3) |
| C++ | [`cpp/n/npb_lu_block_ssor.cpp`](../../../cpp/n/npb_lu_block_ssor.cpp) |
| Elisa | [`elisa/n/npb_lu_block_ssor.elisa`](../../../elisa/n/npb_lu_block_ssor.elisa) |
| Mojo | [`mojo/n/npb_lu_block_ssor.mojo`](../../../mojo/n/npb_lu_block_ssor.mojo) |
| Nim | [`nim/n/npb_lu_block_ssor.nim`](../../../nim/n/npb_lu_block_ssor.nim) |
| Odin | [`odin/n/npb_lu_block_ssor.odin`](../../../odin/n/npb_lu_block_ssor.odin) |
| Rust | [`rust/n/npb_lu_block_ssor.rs`](../../../rust/n/npb_lu_block_ssor.rs) |
| V | [`v/n/npb_lu_block_ssor.v`](../../../v/n/npb_lu_block_ssor.v) |
| Zig | [`zig/n/npb_lu_block_ssor.zig`](../../../zig/n/npb_lu_block_ssor.zig) |
