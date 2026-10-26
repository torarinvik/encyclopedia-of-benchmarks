# MVT: matrix-vector and transposed matrix-vector update

This package ports the `PolyBench/linear-algebra/kernels/mvt/mvt.c` kernel from upstream commit [`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/commit/5d7b75df749241efa7a6e6f5be613d3fcc5cce38). The source defaults to binary64. It initializes two output vectors, two input vectors, and a square matrix from the formulas listed in [`workload.json`](workload.json).

The `mvt` slug accepts a one-element signed 64-bit array `[n]` with `1 <= n <= 64`. It performs the source's first update `x1[i] += A[i][j] * y1[j]` in increasing row and column order, then the transposed update `x2[i] += A[j][i] * y2[j]` in increasing row and column order. To expose both live-out vectors through the suite's scalar ABI, the result adds updated `x1` elements from index 0 upward, followed by updated `x2` elements from index 0 upward. Invalid inputs return `-1e300`.

The bounded implementation preserves the source loop and reduction order; the default `n=2000` dataset is reduced to 64. Ports are provided in C, C3, C++, Elisa, Nim, Odin, Rust, V, and Zig. The kernel file has no inline license header; the PolyBench repository-level Ohio State Software Distribution License is reproduced in this package's [`LICENSE.txt`](LICENSE.txt).

Build and run a port with the shared ABI commands:

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm mvt --language c
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/m/mvt/c/build.json
```
