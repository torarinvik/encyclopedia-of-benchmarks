# ATAX: A-transpose times A times x

This package ports the `PolyBench/linear-algebra/kernels/atax/atax.c` kernel from upstream commit [`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/commit/5d7b75df749241efa7a6e6f5be613d3fcc5cce38). The source uses binary64, initializes `x[i] = 1 + i/n` and `A[i][j] = ((i+j) mod n)/(5*m)`, then clears `y`.

The `atax` slug takes signed 64-bit input `[m, n]`, with both dimensions bounded to 1–64. In increasing row order, it computes each `tmp[i]` by accumulating `A[i][j] * x[j]` for increasing `j`, then adds `A[i][j] * tmp[i]` into `y[j]` in increasing `j` order. This matches the source's row-by-row matrix-vector calculation followed by its transpose contributions, including the source's per-row interleaving. The scalar output is the binary64 sum of final `y[j]` values in increasing column order. Invalid inputs return `-1e300`.

The original default dimensions are reduced to keep calls bounded. Ports are provided in C, C3, C++, Elisa, Nim, Odin, Rust, V, and Zig. See [`workload.json`](workload.json) for source attribution, bounds, and cases. The upstream source has no explicit license notice; these are independently written ports of the published kernel.

Build and run a port with the shared ABI commands:

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm atax --language c
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/a/atax/c/build.json
```
