# 3mm: three matrix multiplications

This package ports the `PolyBench/linear-algebra/kernels/3mm/3mm.c` kernel from upstream commit [`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/commit/5d7b75df749241efa7a6e6f5be613d3fcc5cce38). The source's default data type is binary64. It initializes matrices `A`, `B`, `C`, and `D` from the formulas recorded in [`workload.json`](workload.json).

The `3mm` slug accepts signed 64-bit input `[ni, nj, nk, nl, nm]`, with every dimension bounded to 1–16. It preserves the source's three passes and loop order: `E=A*B` reduces over `k < nk`, `F=C*D` reduces over `k < nm`, then `G=E*F` reduces over `k < nj`. The scalar suite result sums `G` in row-major order. Invalid input returns `-1e300`.

The upstream launcher selects `*.c` with `-I.` and `-DPOLYBENCH_DUMP_ARRAYS`; its header defaults to `LARGE_DATASET` (`NI=800`, `NJ=900`, `NK=1000`, `NL=1100`, `NM=1200`). This suite profile is bounded. Ports are provided in C, C3, C++, Elisa, Nim, Odin, Rust, V, and Zig. The upstream source has no explicit license notice; these are independently written ports of the published kernel.

Build and run a port with the shared ABI commands:

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm 3mm --language c
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/0-9/3mm/c/build.json
```
