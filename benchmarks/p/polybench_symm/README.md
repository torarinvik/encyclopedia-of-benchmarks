# PolyBench SYMM

This package implements the pinned PolyBench/C `symm` kernel from [`symm.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/blas/symm/symm.c) at commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The launcher selects `EXTRALARGE_DATASET`; its source dimensions are `M=2000`, `N=2600`. The suite bounds both dimensions to 1–64.

## Contract

Input is a signed 64-bit array `[m, n]`, where `m` is the square symmetric matrix dimension and `n` is the number of columns in `B` and `C`. Both dimensions must be in 1–64. The kernel uses `alpha=1.5`, `beta=1.2`, initializes `C[i][j]=((i+j) mod 100)/m`, `B[i][j]=((n+i-j) mod 100)/m`, and the lower triangle and diagonal of `A` to `((i+j) mod 100)/m`. The unused upper triangle is initialized to -999 as in the source.

The computation preserves the source loop order: increasing `i`, then `j`, then `k<i`. It applies each lower-triangle contribution to earlier rows of `C`, accumulates `temp2` in increasing `k`, and updates the current `C[i][j]` with the source expression order. The original program dumps every final `C` element; this scalar-output package returns their binary64 sum in row-major order. Inputs with the wrong length or dimensions outside the bound return `-1e300`.

The ports are independently written in C, C3, C++, Elisa, Nim, Odin, Rust, V, and Zig. See [`workload.json`](workload.json) for bounds and deterministic cases, and [`polybench_symm_oracle.py`](../../polybench_symm_oracle.py) for the separate reference model.

## Upstream license

The pinned PolyBench/C source is covered by the Ohio State University Software Distribution License, reproduced in [`LICENSE.txt`](LICENSE.txt). It grants redistribution and use in source and binary forms, with or without modification, subject to retaining its copyright notice, conditions, and capitalized disclaimer. It prohibits using Ohio State University's name to endorse or promote derived products without prior written permission. The license includes its funding and policy statement, warranty and liability disclaimer, and user obligation to indemnify, defend, and hold harmless Ohio State University and its faculty, staff, and students. The complete terms are in `LICENSE.txt`.

## Run

Build a port with the shared `i64_array_float64` ABI and pass its manifest to the suite runner:

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm polybench_symm --language c
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/p/polybench_symm/c/build.json
```
