# gesummv

This package ports the PolyBench/C `gesummv` kernel, which computes two matrix-vector products and combines them as `y = 1.5*(A*x) + 1.2*(B*x)`. The matrices and input vector are initialized by the formulas in the pinned source. To make this vector-output kernel fit the suite's scalar result ABI, the package sums the final `y[i]` values in increasing row order.

## Contract

Input is a one-element signed 64-bit array `[n]`, where `1 <= n <= 64`. The output is binary64. Empty arrays, zero, and dimensions above 64 return `-1e300`. Each row preserves the source's increasing-column accumulation order; the scalar result then accumulates rows from zero upward.

The source inventory is pinned to upstream commit [`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/blas/gesummv/gesummv.c). This package contains independently written implementations. See [`workload.json`](workload.json) and the [shared oracle](../../gesummv_oracle.py).

| Language | Port |
|---|---|
| C | [`c/g/gesummv.c`](../../../c/g/gesummv.c) |
| C3 | [`c3/g/gesummv.c3`](../../../c3/g/gesummv.c3) |
| C++ | [`cpp/g/gesummv.cpp`](../../../cpp/g/gesummv.cpp) |
| Elisa | [`elisa/g/gesummv.elisa`](../../../elisa/g/gesummv.elisa) |
| Nim | [`nim/g/gesummv.nim`](../../../nim/g/gesummv.nim) |
| Odin | [`odin/g/gesummv.odin`](../../../odin/g/gesummv.odin) |
| Rust | [`rust/g/gesummv.rs`](../../../rust/g/gesummv.rs) |
| V | [`v/g/gesummv.v`](../../../v/g/gesummv.v) |
| Zig | [`zig/g/gesummv.zig`](../../../zig/g/gesummv.zig) |

## Run

Build an implementation with the shared `i64_array_float64` ABI and pass its manifest to the suite runner:

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm gesummv --language c
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/g/gesummv/c/build.json
```
