# 2mm: two matrix multiplications

This package ports the `PolyBench/linear-algebra/kernels/2mm/2mm.c` kernel from upstream commit [`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/commit/5d7b75df749241efa7a6e6f5be613d3fcc5cce38). The source's default data type is binary64. It initializes `alpha=1.5`, `beta=1.2` and the matrices from the formulas recorded in [`workload.json`](workload.json).

The `2mm` slug accepts signed 64-bit input `[ni, nj, nk, nl]`, where `A` is `ni×nk`, `B` is `nk×nj`, `C` is `nj×nl`, and `D` is `ni×nl`. Each dimension is bounded to 1–16. The kernel initializes `tmp[i][j]` to zero and accumulates `alpha*A[i][k]*B[k][j]` with `k` ascending, then scales each `D[i][l]` by `beta` and accumulates `tmp[i][j]*C[j][l]` with `j` ascending. The scalar suite result sums final `D` in row-major order. Invalid input returns `-1e300`.

The upstream launcher selects `*.c` with `-I.` and `-DPOLYBENCH_DUMP_ARRAYS`; its header defaults to `LARGE_DATASET` (`NI=800`, `NJ=900`, `NK=1100`, `NL=1200`). This suite profile is bounded. Ports are provided in C, C3, C++, Elisa, Nim, Odin, Rust, V, and Zig. The upstream source has no explicit license notice; these are independently written ports of the published kernel.

Build and run a port with the shared ABI commands:

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm 2mm --language c
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/0-9/2mm/c/build.json
```
