# ATAX: A-transpose times A times x

This package ports the `PolyBench/linear-algebra/kernels/atax/atax.c` kernel from upstream commit [`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/commit/5d7b75df749241efa7a6e6f5be613d3fcc5cce38). The source uses binary64, initializes `x[i] = 1 + i/n` and `A[i][j] = ((i+j) mod n)/(5*m)`, then clears `y`.

The `atax` slug takes signed 64-bit input `[m, n]`, with both dimensions bounded to 1–64. In increasing row order, it computes each `tmp[i]` by accumulating `A[i][j] * x[j]` for increasing `j`, then adds `A[i][j] * tmp[i]` into `y[j]` in increasing `j` order. This matches the source's row-by-row matrix-vector calculation followed by its transpose contributions, including the source's per-row interleaving. The scalar output is the binary64 sum of final `y[j]` values in increasing column order. Invalid inputs return `-1e300`.

The original default dimensions are reduced to keep calls bounded. Ports are provided in C, C3, C++, Elisa, Nim, Odin, Rust, V, and Zig. See [`workload.json`](workload.json) for source attribution, bounds, and cases.

## Upstream license

The source belongs to PolyBench/C and is covered by the Ohio State University Software Distribution License in [`LICENSE.txt`](LICENSE.txt). That license permits redistribution and use of source and binary forms, with or without modification, provided its copyright notice, conditions, and capitalized disclaimer are retained. It prohibits using Ohio State University’s name to endorse or promote derived products without prior written permission. The disclaimer also states that users assume the risk and requires users to indemnify, defend, and hold harmless Ohio State University and its faculty, staff, and students for claims and costs connected to access or use. The complete notice, including its funding and policy statement, disclaimer, and indemnification language, is reproduced in `LICENSE.txt`.

Build and run a port with the shared ABI commands:

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm atax --language c
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/a/atax/c/build.json
```
