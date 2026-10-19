# Jacobi 1D stencil

This package ports `init_array` and `kernel_jacobi_1d` from PolyBench/C
[`jacobi-1d.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/stencils/jacobi-1d/jacobi-1d.c)
at commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The default source type
is binary64. Its launcher selects `EXTRALARGE_DATASET` (`N=4000`, `TSTEPS=1000`);
this bounded suite profile uses `1 <= n <= 30` and `0 <= tsteps <= 20`, the
source's `MINI_DATASET` size and step count.

Input is the two-element binary64 array `[n, tsteps]`, with exact integer
values. Initialization follows the source: `A[i] = (i + 2) / n` and
`B[i] = (i + 3) / n`. Each step first updates B's interior from A, then updates
A's interior from B, using the source coefficient `0.33333` and ascending
index order. Boundary elements retain their initialized values. The function
returns all n final values of A in binary64. Invalid input returns `-1`; a null
output pointer or capacity below n returns `-2` without writing output.

The independent reference is
[`benchmarks/jacobi_1d_oracle.py`](../../jacobi_1d_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [c/j/jacobi_1d.c](../../../c/j/jacobi_1d.c) |
| C3 | [c3/j/jacobi_1d.c3](../../../c3/j/jacobi_1d.c3) |
| C++ | [cpp/j/jacobi_1d.cpp](../../../cpp/j/jacobi_1d.cpp) |
| Elisa | [elisa/j/jacobi_1d.elisa](../../../elisa/j/jacobi_1d.elisa) |
| Nim | [nim/j/jacobi_1d.nim](../../../nim/j/jacobi_1d.nim) |
| Odin | [odin/j/jacobi_1d.odin](../../../odin/j/jacobi_1d.odin) |
| Rust | [rust/j/jacobi_1d.rs](../../../rust/j/jacobi_1d.rs) |
| V | [v/j/jacobi_1d.v](../../../v/j/jacobi_1d.v) |
| Zig | [zig/j/jacobi_1d.zig](../../../zig/j/jacobi_1d.zig) |

The shared `float64_slice_io` suite will use these commands after runner
integration:

```sh
python3 benchmarks/build_abi.py --family float64_slice_io --algorithm jacobi_1d --language c
python3 benchmarks/run_float64_slice_io.py --build-manifest build/float64_slice_io/j/jacobi_1d/c/build.json
python3 benchmarks/verify_float64_slice_io.py --algorithm jacobi_1d --languages c
```
