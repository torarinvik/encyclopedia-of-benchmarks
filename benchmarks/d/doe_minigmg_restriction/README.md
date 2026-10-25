# DOE miniGMG Cell-Centered Restriction

This package ports the cell-centered restriction kernel `restriction` from
[`DOE_ProxyApps_C/miniGMG/restriction.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/DOE_ProxyApps_C/miniGMG/restriction.inc)
at pinned `lac-dcc/Benchmarks` commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The source operator maps each
coarse-grid cell to the corresponding nonoverlapping 2×2×2 fine-grid block,
adds its eight values in source order, and multiplies the sum by `0.125`.
This is a compact multigrid coarsening operation, distinct from Jacobi/heat
stencils, which update values on the same grid.

The `i64_array_float64` ABI exports `doe_minigmg_restriction(values, length)`.
Input is `[nx, ny, nz, fine_grid...]`, with `nx`, `ny`, and `nz` each even in
`[2, 8]`. The fine grid has exactly `nx*ny*nz` signed integer cells in
row-major order with x varying fastest. Each cell must be in `[-32768, 32767]`;
the exact input length is `3 + nx*ny*nz`. This bounds the fine grid to 512
cells and keeps the source's binary64 means and checksum exact.

The benchmark projects the restricted coarse grid to one scalar so it fits the
suite's scalar-result ABI. In source traversal order (coarse k, j, i), let
`r[q]` be the mean of coarse cell `q`, where `q` starts at zero. The result is
`sum((q + 1) * r[q] * r[q])`. The position-weighted squared checksum makes the
result depend on every coarse-cell result while retaining fractional means.
Invalid input returns `-1e300`. The output is exactly representable in
binary64 for the bounded domain, so the comparison tolerance is zero.

[`workload.json`](workload.json) contains hand-derived constant, fractional,
multi-cell, malformed-dimension, malformed-length, range, and null-input cases.
[`benchmarks/doe_minigmg_restriction_oracle.py`](../../doe_minigmg_restriction_oracle.py)
is an independently written row-major reference that can calculate any valid
bounded input.

The pinned miniGMG subtree includes an explicit BSD-3-Clause-style license and
an additional enhancement-license paragraph. Its complete text is preserved
in [`LICENSE.txt`](LICENSE.txt); no upstream implementation code is copied
into these ports. The ports are written from the documented source behavior.
