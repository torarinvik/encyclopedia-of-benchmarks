# PolyBench FDTD 2D

This package ports the initialized `kernel_fdtd_2d` from PolyBench/C at pinned `lac-dcc/Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The launcher selects `LARGE_DATASET` (`TMAX=500`, `NX=1000`, `NY=1200`); this bounded profile accepts `0<=tmax<=4` and `1<=nx,ny<=6`.

## Contract

The `float64_slice_io` symbol is `fdtd_2d(input, input_length, output, output_capacity)`. Input is `[tmax,nx,ny]` as finite, exact-integer binary64 values. The source initialization is retained: `_fict_[t]=t`, `ex[i][j]=(i*(j+1))/nx`, `ey[i][j]=(i*(j+2))/ny`, and `hz[i][j]=(i*(j+3))/nx`, with binary64 arithmetic. Each step performs the source loops in order: assign `ey[0][j]` from `_fict_[t]`, update remaining `ey`, update `ex` for `j>=1`, then update `hz` for `i<nx-1,j<ny-1`. The two differences in the `hz` expression are added left-to-right. Output concatenates complete `ex`, `ey`, and `hz` matrices, each row-major. It is a numeric vector, not PolyBench's formatted dump.

Malformed input returns -1. Null or undersized output returns -2 after input validation. Implementations stage all outputs before writing, so errors leave the output untouched. Maximum output is 108 doubles.

## Workload and oracle

[`workload.json`](workload.json) specifies valid, boundary, and invalid cases. [`benchmarks/fdtd_2d_oracle.py`](../../fdtd_2d_oracle.py) independently evaluates the initialization and source-ordered stencil.

## Implementations

The nine ports are in the corresponding `c/f`, `c3/f`, `cpp/f`, `elisa/f`, `nim/f`, `odin/f`, `rust/f`, `v/f`, and `zig/f` directories.

## Pinned source and license

- [fdtd-2d.c](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/stencils/fdtd-2d/fdtd-2d.c)
- [fdtd-2d.h](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/stencils/fdtd-2d/fdtd-2d.h)
- [info.sh](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/stencils/fdtd-2d/info.sh)
- [`LICENSE.txt`](LICENSE.txt) reproduces PolyBench's pinned Ohio State University Software Distribution License.
