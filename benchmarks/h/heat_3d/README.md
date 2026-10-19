# PolyBench Heat 3D

This package ports the initialized `kernel_heat_3d` from PolyBench/C at pinned `lac-dcc/Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. Its launcher selects `EXTRALARGE_DATASET` (`TSTEPS=1000`, `N=200`); this suite bounds `1<=n<=6` and `0<=tsteps<=4`.

## Contract

The `float64_slice_io` symbol is `polybench_heat_3d(input,input_length,output,output_capacity)`. Input is `[n,tsteps]` as finite exact-integer binary64 values. Both A and B start with `((i+j+(n-k))*10)/n` in binary64. For each requested timestep, update B at interior coordinates in ascending `i,j,k`, then update A over the same interior using B. Each update is the source's ordered sum of three axis second differences scaled by 0.125, followed by the center value. Boundary values remain initialized. Return complete final A in `i,j,k` row-major order. The bounded input timestep controls the source recurrence count in place of the launcher's fixed compile-time count.

Invalid input returns -1. Null or undersized output returns -2 after validation. Results are staged before output writes, so errors do not modify output. Maximum output is 216 doubles; output is numeric binary64, not PolyBench's text dump.

## Workload and oracle

[`workload.json`](workload.json) defines valid and invalid cases. [`benchmarks/heat_3d_oracle.py`](../../heat_3d_oracle.py) independently initializes the two fields and applies the source-ordered recurrence.

## Ports

Language implementations are in `c/h/heat_3d`, `c3/h/heat_3d`, `cpp/h/heat_3d`, `elisa/h/heat_3d`, `nim/h/heat_3d`, `odin/h/heat_3d`, `rust/h/heat_3d`, `v/h/heat_3d`, and `zig/h/heat_3d`.

## Pinned source and license

- [heat-3d.c](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/stencils/heat-3d/heat-3d.c)
- [heat-3d.h](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/stencils/heat-3d/heat-3d.h)
- [info.sh](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/stencils/heat-3d/info.sh)
- [`LICENSE.txt`](LICENSE.txt) reproduces the pinned Ohio State University Software Distribution License, including its redistribution conditions, public-release statement, disclaimer, and indemnification terms.
