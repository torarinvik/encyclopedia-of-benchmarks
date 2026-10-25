# Himeno Poisson relaxation

This package is an independent bounded implementation of the weighted point-Jacobi core used by the pinned lac-dcc/Benchmarks Misc/himenobmtxpa benchmark. It solves the zero-source 3D Poisson profile with fixed coefficients and reports the squared residual sum from the final iteration.

## Contract

The ABI is float64_slice_io, symbol himenobmtxpa. Input is exactly [nx, ny, nz, iterations], with each grid side from 2 through 6 and iterations from 1 through 4. Values are finite, exact integers. Grid coordinates include the fixed boundary cells. Initialize each field value as binary32 i*i / ((nx-1)*(nx-1)); boundaries remain unchanged. For each iteration, visit interior coordinates in ascending i,j,k order, sum the six axis neighbors, compute ss = neighbor_sum * (1/6) - p, accumulate gosa += ss*ss, and stage p + 0.8*ss. Copy the staged interior values into p after the sweep. The pinned coefficient setup makes its mixed-derivative and source terms zero, so the bounded contract retains only the active six-neighbor Poisson update. All arithmetic and the final residual accumulation use binary32; the one output element widens the final gosa to binary64.

The routine returns one output element. Invalid input returns -1; null output or capacity below one returns -2 without writing. The profile is capped at 216 cells and four iterations. The maximum-profile workload uses only small static arrays.

## Workload and oracle

workload.json defines the bounded profile, source pin, and ABI cases. benchmarks/himenobmtxpa_oracle.py independently implements the recurrence with explicit binary32 rounding.

## Source provenance and license

- Pinned himenobmtxpa.c: https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/himenobmtxpa/himenobmtxpa.c
- Pinned info.sh: https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/himenobmtxpa/info.sh

The pinned source has no explicit license grant. These implementations were written independently from the published weighted Jacobi equations and observed initialization and output behavior; no upstream license is inferred.

## Ports

The nine implementations are in c/h, c3/h, cpp/h, elisa/h, nim/h, odin/h, rust/h, v/h, and zig/h as himenobmtxpa source files.
