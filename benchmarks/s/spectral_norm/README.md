# Spectral norm

This package ports the implicit-matrix power iteration in the lac-dcc BenchmarkGame `spectral-norm` source. It starts with an all-ones vector and performs ten paired multiplications by `AᵀA`, then returns `sqrt((u·v)/(v·v))`. The matrix entry is `1 / (((i+j)(i+j+1))/2 + i + 1)`; no matrix is allocated.

## Contract

Input is a one-element signed 64-bit array `[n]`, with `1 <= n <= 64`. The upper bound keeps the source's quadratic matrix-vector loops practical in repeated suite calls. The output is binary64. Empty arrays, zero, and dimensions above 64 return `-1e300`. The suite follows the source's ten-iteration loop and summation order; it does not replace the iterative result with an exact eigenvalue.

The source inventory is pinned to upstream commit [`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/BenchmarkGame/spectral-norm/spectral-norm.c), whose C file credits Sebastien Loisel and carries no explicit license notice. This package contains independently written implementations. See [`workload.json`](workload.json) and the [shared oracle](../../spectral_norm_oracle.py).

| Language | Port |
|---|---|
| C | [`c/s/spectral_norm.c`](../../../c/s/spectral_norm.c) |
| C3 | [`c3/s/spectral_norm.c3`](../../../c3/s/spectral_norm.c3) |
| C++ | [`cpp/s/spectral_norm.cpp`](../../../cpp/s/spectral_norm.cpp) |
| Elisa | [`elisa/s/spectral_norm.elisa`](../../../elisa/s/spectral_norm.elisa) |
| Nim | [`nim/s/spectral_norm.nim`](../../../nim/s/spectral_norm.nim) |
| Odin | [`odin/s/spectral_norm.odin`](../../../odin/s/spectral_norm.odin) |
| Rust | [`rust/s/spectral_norm.rs`](../../../rust/s/spectral_norm.rs) |
| V | [`v/s/spectral_norm.v`](../../../v/s/spectral_norm.v) |
| Zig | [`zig/s/spectral_norm.zig`](../../../zig/s/spectral_norm.zig) |

## Run

Build any implementation with the shared `i64_array_float64` ABI and pass its
manifest to the suite runner:

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm spectral_norm --language c
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/s/spectral_norm/c/build.json
```
