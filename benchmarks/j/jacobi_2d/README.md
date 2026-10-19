# Jacobi 2D stencil

This package ports `init_array` and `kernel_jacobi_2d` from PolyBench/C
[`jacobi-2d.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/stencils/jacobi-2d/jacobi-2d.c)
at commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The default source type
is binary64. Its launcher selects `EXTRALARGE_DATASET` (`N=2800`, `TSTEPS=1000`);
this bounded suite profile uses `1 <= n <= 30` and `0 <= tsteps <= 20`, the
source's `MINI_DATASET` size and step count.

Input is the two-element binary64 array `[n, tsteps]`, with exact integer
values. Initialization follows the source:
`A[i][j] = (i * (j + 2) + 2) / n` and
`B[i][j] = (i * (j + 3) + 3) / n`. Each step updates B's interior from A in
ascending row and column order, then updates A's interior from B in the same
order. Both sweeps use the source's `0.2` coefficient and neighbor order
`center, left, right, down, up`. Boundary cells keep their initialized values.
The function returns the complete final A matrix as a row-major binary64
vector. Invalid input returns `-1`; a null output pointer or capacity below
`n*n` returns `-2` without writing output.

The independent reference is
[`benchmarks/jacobi_2d_oracle.py`](../../jacobi_2d_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [c/j/jacobi_2d.c](../../../c/j/jacobi_2d.c) |
| C3 | [c3/j/jacobi_2d.c3](../../../c3/j/jacobi_2d.c3) |
| C++ | [cpp/j/jacobi_2d.cpp](../../../cpp/j/jacobi_2d.cpp) |
| Elisa | [elisa/j/jacobi_2d.elisa](../../../elisa/j/jacobi_2d.elisa) |
| Nim | [nim/j/jacobi_2d.nim](../../../nim/j/jacobi_2d.nim) |
| Odin | [odin/j/jacobi_2d.odin](../../../odin/j/jacobi_2d.odin) |
| Rust | [rust/j/jacobi_2d.rs](../../../rust/j/jacobi_2d.rs) |
| V | [v/j/jacobi_2d.v](../../../v/j/jacobi_2d.v) |
| Zig | [zig/j/jacobi_2d.zig](../../../zig/j/jacobi_2d.zig) |

The shared `float64_slice_io` suite will use these commands after runner
integration:

```sh
python3 benchmarks/build_abi.py --family float64_slice_io --algorithm jacobi_2d --language c
python3 benchmarks/run_float64_slice_io.py --build-manifest build/float64_slice_io/j/jacobi_2d/c/build.json
python3 benchmarks/verify_float64_slice_io.py --algorithm jacobi_2d --languages c
```
