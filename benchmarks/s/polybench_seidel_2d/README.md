# PolyBench Seidel 2D

This package ports PolyBench/C's initialized `kernel_seidel_2d` at pinned `lac-dcc/Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The unique slug `polybench_seidel_2d` separates this matrix stencil from the local `gauss_seidel_method`. The launcher selects `EXTRALARGE_DATASET` (`TSTEPS=1000`, `N=4000`); this bounded profile accepts `1<=n<=6` and `0<=tsteps<=4`.

## Contract

The `float64_slice_io` symbol is `polybench_seidel_2d(input,input_length,output,output_capacity)`. Input is `[n,tsteps]` as finite, exact-integer binary64 values. Initialize `A[i][j]=((double)i*(j+2)+2)/n`. For each requested step, visit `i=1..n-2` ascending, then `j=1..n-2` ascending, immediately replacing each cell with the sum of its 3×3 neighborhood (including its current value) divided by 9. This is an in-place Seidel sweep: later cells observe earlier updates from the same sweep. Boundaries remain at their initialized values.

Return all `n*n` cells row-major. Invalid input returns -1. Null or undersized output returns -2 after validation; implementations stage results before writing, so errors leave output untouched. The maximum output is 36 doubles, returned numerically rather than in the source's formatted dump.

## Workload and oracle

[`workload.json`](workload.json) defines bounded valid and invalid cases. [`benchmarks/polybench_seidel_2d_oracle.py`](../../polybench_seidel_2d_oracle.py) independently applies the in-place traversal and source initialization.

## Ports

The nine implementations are in the corresponding `c/s`, `c3/s`, `cpp/s`, `elisa/s`, `nim/s`, `odin/s`, `rust/s`, `v/s`, and `zig/s` directories as `polybench_seidel_2d` source files.

## Pinned source and license

- [seidel-2d.c](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/stencils/seidel-2d/seidel-2d.c)
- [seidel-2d.h](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/stencils/seidel-2d/seidel-2d.h)
- [info.sh](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/stencils/seidel-2d/info.sh)
- [`LICENSE.txt`](LICENSE.txt) contains the full pinned Ohio State University Software Distribution License, including redistribution conditions, disclaimer, public-release statement, and indemnification terms.
