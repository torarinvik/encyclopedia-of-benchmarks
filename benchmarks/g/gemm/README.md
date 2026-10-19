# gemm

This package ports the PolyBench/C `gemm` kernel, which computes `C := alpha*A*B + beta*C` for `A` shaped `ni × nk`, `B` shaped `nk × nj`, and `C` shaped `ni × nj`. The pinned source initializes `alpha=1.5`, `beta=1.2`, and the three matrices with the formulas recorded in [`workload.json`](workload.json).

## Contract

Input is a three-element signed 64-bit array `[ni, nj, nk]`; each dimension is bounded to 1–64. The binary64 result is the sum of final `C[i][j]` values in row-major order, matching the source's live-out print order. Each row is first scaled by `beta` in increasing column order. Then `k` is visited in increasing order, and each update is applied across increasing `j` as `C[i][j] += alpha * A[i][k] * B[k][j]`. Ports preserve that scaling and update order. Invalid inputs return `-1e300`.

The source uses binary64 by default, and its launcher selects `EXTRALARGE_DATASET` (`ni=2000`, `nj=2300`, `nk=2600`). This suite profile bounds every dimension to 1–64. The source and launcher are pinned to upstream commit [`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/blas/gemm). The ports are independently written.

| Language | Port |
|---|---|
| C | [`c/g/gemm.c`](../../../c/g/gemm.c) |
| C3 | [`c3/g/gemm.c3`](../../../c3/g/gemm.c3) |
| C++ | [`cpp/g/gemm.cpp`](../../../cpp/g/gemm.cpp) |
| Elisa | [`elisa/g/gemm.elisa`](../../../elisa/g/gemm.elisa) |
| Nim | [`nim/g/gemm.nim`](../../../nim/g/gemm.nim) |
| Odin | [`odin/g/gemm.odin`](../../../odin/g/gemm.odin) |
| Rust | [`rust/g/gemm.rs`](../../../rust/g/gemm.rs) |
| V | [`v/g/gemm.v`](../../../v/g/gemm.v) |
| Zig | [`zig/g/gemm.zig`](../../../zig/g/gemm.zig) |

Build a port with the shared ABI commands:

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm gemm --language c
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/g/gemm/c/build.json
```
