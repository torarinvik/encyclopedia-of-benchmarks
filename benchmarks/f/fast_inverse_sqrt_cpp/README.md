# Fast inverse square root (C++ double precision)

## Contract

The input is one finite positive binary64 value in `[1e-6, 1e6]`. The routine returns the Quake-style inverse-square-root approximation from the pinned C++ source, using a binary64 bit seed and two Newton corrections. Invalid inputs return `-1.0`.

The seed is formed as `0x5fe6eb50c7b537a9 - (bits >> 1)`. Each correction preserves the source operation order `y * (1.5 - (x2 * y * y))`, where `x2` is half of the original input. This benchmark selects `Fast_InvSqrt<double, 2>` explicitly. The workload compares binary64 results with absolute tolerance `1e-15` and relative tolerance `1e-12`.

## Workload and build

[`workload.json`](workload.json) covers the input bounds, representative powers and fractional values, and invalid inputs.

```sh
python3 benchmarks/build_abi.py --family float64_unary --algorithm fast_inverse_sqrt_cpp --language rust
python3 benchmarks/run_float64_unary.py --build-manifest build/float64_unary/f/fast_inverse_sqrt_cpp/rust/build.json
```

## Implementations

| Language | Port |
| --- | --- |
| C | [`c/f/fast_inverse_sqrt_cpp.c`](../../../c/f/fast_inverse_sqrt_cpp.c) |
| C3 | [`c3/f/fast_inverse_sqrt_cpp.c3`](../../../c3/f/fast_inverse_sqrt_cpp.c3) |
| C++ | [`cpp/f/fast_inverse_sqrt_cpp.cpp`](../../../cpp/f/fast_inverse_sqrt_cpp.cpp) |
| Elisa | [`elisa/f/fast_inverse_sqrt_cpp.elisa`](../../../elisa/f/fast_inverse_sqrt_cpp.elisa) |
| Nim | [`nim/f/fast_inverse_sqrt_cpp.nim`](../../../nim/f/fast_inverse_sqrt_cpp.nim) |
| Odin | [`odin/f/fast_inverse_sqrt_cpp.odin`](../../../odin/f/fast_inverse_sqrt_cpp.odin) |
| Rust | [`rust/f/fast_inverse_sqrt_cpp.rs`](../../../rust/f/fast_inverse_sqrt_cpp.rs) |
| V | [`v/f/fast_inverse_sqrt_cpp.v`](../../../v/f/fast_inverse_sqrt_cpp.v) |
| Zig | [`zig/f/fast_inverse_sqrt_cpp.zig`](../../../zig/f/fast_inverse_sqrt_cpp.zig) |

## Upstream references

- [TheAlgorithms/C-Plus-Plus `inv_sqrt.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/inv_sqrt.cpp)
- [TheAlgorithms/C-Plus-Plus-1 `inv_sqrt.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/inv_sqrt.cpp)
