# covariance

This package ports the PolyBench/C `covariance` kernel from the pinned lac-dcc revision. It takes `[n, m]`, where `n` is the number of observations and `m` is the number of variables. The source initializes `float_n` to `n` and initializes `data[i][j]` as `(double(i) * j) / m`.

## Contract

Input is a two-element signed 64-bit array. The observation count is bounded to 2–64 and the variable count to 1–64; the lower bound on `n` keeps the sample covariance divisor `n-1` positive. The output is the binary64 sum of the final covariance matrix in row-major order, matching the source's printed live-out matrix. Each column mean is accumulated over observations in increasing order and divided by `n`; data is centered in row-major order. Covariance entries are then computed for `i` ascending and `j` from `i` upward, with the inner observation reduction in ascending `k`; each result is divided by `n-1` and copied to its symmetric entry. Invalid inputs return `-1e300`.

The source defaults to binary64. Its launcher does not select a dataset flag, so the header's default LARGE profile is `m=1200`, `n=1400`; this suite profile bounds both dimensions to at most 64. Source and launcher are pinned to upstream commit [`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/datamining/covariance). Ports are independently written.

| Language | Port |
|---|---|
| C | [`c/c/covariance.c`](../../../c/c/covariance.c) |
| C3 | [`c3/c/covariance.c3`](../../../c3/c/covariance.c3) |
| C++ | [`cpp/c/covariance.cpp`](../../../cpp/c/covariance.cpp) |
| Elisa | [`elisa/c/covariance.elisa`](../../../elisa/c/covariance.elisa) |
| Nim | [`nim/c/covariance.nim`](../../../nim/c/covariance.nim) |
| Odin | [`odin/c/covariance.odin`](../../../odin/c/covariance.odin) |
| Rust | [`rust/c/covariance.rs`](../../../rust/c/covariance.rs) |
| V | [`v/c/covariance.v`](../../../v/c/covariance.v) |
| Zig | [`zig/c/covariance.zig`](../../../zig/c/covariance.zig) |

Build a port with the shared ABI commands:

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm covariance --language c
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/c/covariance/c/build.json
```
