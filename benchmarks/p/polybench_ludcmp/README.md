# PolyBench LUDCMP

This package implements the pinned PolyBench/C LU decomposition and solve kernel from [`ludcmp.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/solvers/ludcmp/ludcmp.c) at commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The launcher selects `ludcmp.c` without a dataset override; the header defaults to double precision and `LARGE_DATASET`, `N=2000`. This suite profile bounds the dimension to 1–64.

## Contract

Input is a one-element signed 64-bit array `[n]`, where `1 <= n <= 64`. The kernel uses binary64. Initialization sets `b[i] = ((i + 1) / n) / 2 + 4`, zeroes `x` and `y`, creates the lower-triangular `A0` using the source's signed remainder expression `(-j % n) / n + 1`, zeroes its upper triangle, and resets its diagonal to one. It forms `A = A0 * A0ᵀ` with the source's `t`, `r`, `s` accumulation order.

The kernel then computes an unpivoted LU factorization with the original `i`, `j`, `k` loop order, solves `L*y=b` by forward substitution, and solves `U*x=y` by backward substitution. The original program prints the `x` vector with two decimal places. To fit the suite's scalar binary64 ABI, this package returns the sum of `x` in increasing index order; the independent oracle preserves the source arithmetic and loop ordering before applying that reduction. Wrong-length and out-of-range inputs return `-1e300`.

Ports are provided in C, C3, C++, Elisa, Nim, Odin, Rust, V, and Zig. See [`workload.json`](workload.json) for bounded fixtures and [`polybench_ludcmp_oracle.py`](../../polybench_ludcmp_oracle.py) for the independent reference model.

## Upstream license

The pinned PolyBench/C source is covered by the Ohio State University Software Distribution License, reproduced in [`LICENSE.txt`](LICENSE.txt). It permits redistribution and use in source and binary forms, with or without modification, under its stated retention conditions. It also includes a no-endorsement condition, funding and policy statement, warranty and liability disclaimer, and user indemnification, defense, and hold-harmless obligation. Preserve the complete notice when redistributing this package.

## Run

Build a port with the shared `i64_array_float64` ABI and pass its manifest to the suite runner:

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm polybench_ludcmp --language c
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/p/polybench_ludcmp/c/build.json
```
