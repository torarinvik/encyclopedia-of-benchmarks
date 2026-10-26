# GEMVER: matrix and vector updates

This package ports the `PolyBench/linear-algebra/blas/gemver/gemver.c` kernel from upstream commit [`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/commit/5d7b75df749241efa7a6e6f5be613d3fcc5cce38). The source's default data type is binary64. It initializes `alpha=1.5`, `beta=1.2`, `u1[i]=i`, and the remaining vectors and matrix from the formulas recorded in [`workload.json`](workload.json).

The `gemver` slug accepts signed 64-bit input `[n]`, with `n` bounded to 1–64. It preserves the source's four passes: update `A` in row-major order; update each `x[i]` from `A[j][i]` and `y[j]` in increasing `j`; add `z` to `x`; then update each `w[i]` from `A[i][j]` and `x[j]` in increasing `j`. The scalar result sums final `w[i]` in ascending order. Invalid inputs return `-1e300`.

The upstream launcher selects `EXTRALARGE_DATASET` (`N=20000`); this suite profile uses bounded dimensions. Ports are provided in C, C3, C++, Elisa, Nim, Odin, Rust, V, and Zig. The kernel file has no inline license header; the PolyBench repository-level Ohio State Software Distribution License is reproduced in this package's [`LICENSE.txt`](LICENSE.txt).

Build and run a port with the shared ABI commands:

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm gemver --language c
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/g/gemver/c/build.json
```
