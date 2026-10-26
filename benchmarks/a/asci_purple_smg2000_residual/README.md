# ASCI Purple SMG 7-point residual

This package isolates the structured residual operation `r = b - A*x` used by
the pinned ASCI Purple `smg2000` benchmark. The source driver identifies its
operator as the standard 3D 7-point Laplacian and constructs the anisotropic
coefficients `cx=0.1`, `cy=1.0`, `cz=10.0`. The package is a bounded clean-room
profile of that kernel, not a port of HYPRE's complete semi-coarsening
multigrid solver, MPI communication, hierarchy setup, or convergence loop.

## Contract

The `float64_slice_io` symbol is `asci_purple_smg2000_residual(input,
input_length, output, output_capacity)`. Input is
`[nx, ny, nz, x[all cells], b[all cells]]`, with each side from 2 through 5.
The arrays are row-major with `k` contiguous, and each field element is an
exact integral binary64 value in `[-1000, 1000]`. The exact input length is
`3 + 2*nx*ny*nz`.

For each cell, compute `r=b-A*x` using the source driver's fixed anisotropy.
The diagonal coefficient is `2*(0.1+1+10)=22.2`; each in-domain axial
neighbor contributes `-0.1`, `-1`, or `-10` for the `i`, `j`, or `k` axis.
Missing out-of-domain neighbors are omitted while the diagonal remains 22.2,
matching the bounded finite-grid stencil. The output contains all residuals
in row-major order and the function returns the cell count. Invalid input
returns `-1`; null output or insufficient capacity returns `-2`; errors write
no output. Coefficients are evaluated as exact integer tenths before the
binary64 conversion, which keeps the launcher defaults reproducible across
the nine ports.

This is not a duplicate of the local JDS sparse matrix-vector product: it
returns the residual of a fixed structured anisotropic 7-point operator.
It is also distinct from miniAMR's neighborhood averages, PolyBench heat
diffusion, and iterative point-Jacobi relaxation; those update or average
fields rather than compute this `b-A*x` vector.

The independent oracle is
[`benchmarks/asci_purple_smg2000_residual_oracle.py`](../../asci_purple_smg2000_residual_oracle.py).
[`workload.json`](workload.json) provides bounded valid and malformed cases.

## Provenance and rights

The source is pinned to `lac-dcc/Benchmarks` commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`:

- [`ASCI_Purple/smg2000.c`, lines 268–402](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/ASCI_Purple/smg2000.c#L268-L402), the 3D stencil setup and coefficients.
- [`ASCI_Purple/smg_residual.c`, lines 142–295](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/ASCI_Purple/smg_residual.c#L142-L295), `hypre_SMGResidual`, which copies `b` and subtracts stencil products.
- [`ASCI_Purple/info.sh`, lines 1–20](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/ASCI_Purple/info.sh#L1-L20), the benchmark launcher and default anisotropy.

The source files carry a 1997 Regents of the University of California
copyright notice and refer to `COPYRIGHT_and_DISCLAIMER`, which is absent from
the pinned `ASCI_Purple` directory and repository root. No explicit license
grant for these files was located. These ports, oracle, workload, and docs are
written independently from the mathematical contract; no upstream source
code is included or translated. This note does not assert a license for the
upstream source.

## Ports

| Language | Source |
| --- | --- |
| C | [`c/a/asci_purple_smg2000_residual.c`](../../../c/a/asci_purple_smg2000_residual.c) |
| C3 | [`c3/a/asci_purple_smg2000_residual.c3`](../../../c3/a/asci_purple_smg2000_residual.c3) |
| C++ | [`cpp/a/asci_purple_smg2000_residual.cpp`](../../../cpp/a/asci_purple_smg2000_residual.cpp) |
| Elisa | [`elisa/a/asci_purple_smg2000_residual.elisa`](../../../elisa/a/asci_purple_smg2000_residual.elisa) |
| Nim | [`nim/a/asci_purple_smg2000_residual.nim`](../../../nim/a/asci_purple_smg2000_residual.nim) |
| Odin | [`odin/a/asci_purple_smg2000_residual.odin`](../../../odin/a/asci_purple_smg2000_residual.odin) |
| Rust | [`rust/a/asci_purple_smg2000_residual.rs`](../../../rust/a/asci_purple_smg2000_residual.rs) |
| V | [`v/a/asci_purple_smg2000_residual.v`](../../../v/a/asci_purple_smg2000_residual.v) |
| Zig | [`zig/a/asci_purple_smg2000_residual.zig`](../../../zig/a/asci_purple_smg2000_residual.zig) |
