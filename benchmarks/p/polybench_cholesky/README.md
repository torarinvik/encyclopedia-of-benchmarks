# PolyBench Cholesky

This package implements the pinned PolyBench/C Cholesky kernel from [`cholesky.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/solvers/cholesky/cholesky.c) at commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The launcher uses the header's default `LARGE_DATASET`, `N=2000`. The suite bounds `n` to 1–64.

## Contract

Input is a one-element signed 64-bit array `[n]`, where `1 <= n <= 64`. The source uses binary64. Its initializer first builds lower-triangular `A0` with `A0[i][j] = ((-j % n) / n) + 1` for `j <= i`, zeroes the upper triangle, and resets the diagonal to one. Since `0 <= j < n`, C's signed remainder makes `-j % n` equal `-j`. It then computes `B = A0 * A0ᵀ` using the source's `t`, `r`, `s` loops and copies `B` back into `A`.

The factorization preserves the source order: for increasing `i`, it updates each `j < i` using increasing `k < j`, divides by the earlier diagonal, then updates the diagonal using increasing `k < i` and takes its square root. The original program dumps the final lower triangle. This scalar-output package returns the binary64 sum of those lower-triangle elements in row-major order. Wrong-length or out-of-range inputs return `-1e300`.

Ports are provided in C, C3, C++, Elisa, Nim, Odin, Rust, V, and Zig. See [`workload.json`](workload.json) for the bounded cases and [`polybench_cholesky_oracle.py`](../../polybench_cholesky_oracle.py) for the independent reference model.

## Upstream license

The pinned PolyBench/C source is covered by the Ohio State University Software Distribution License, reproduced in [`LICENSE.txt`](LICENSE.txt). It grants redistribution and use in source and binary forms, with or without modification, subject to retaining its copyright notice, conditions, and capitalized disclaimer. It prohibits using Ohio State University's name to endorse or promote derived products without prior written permission. The license includes its funding and policy statement, warranty and liability disclaimer, and user obligation to indemnify, defend, and hold harmless Ohio State University and its faculty, staff, and students. The complete terms are in `LICENSE.txt`.

## Run

Build a port with the shared `i64_array_float64` ABI and pass its manifest to the suite runner:

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm polybench_cholesky --language c
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/p/polybench_cholesky/c/build.json
```
