# Go fast inverse square root

## Contract

Use the unary `float64_unary` ABI: `double fast_inverse_sqrt_go(double x)`. Inputs must be finite and in `[1e-6, 1e6]`; other values return `-1.0`.

The input is rounded to binary32 before the algorithm runs. The seed uses the magic constant `0x5f3759df` and `0x5f3759df - (bits >> 1)`. It then performs the Go source's two Newton corrections entirely in binary32, rounding the intermediate products and correction at each step. The final binary32 value is widened to binary64 for the ABI result. This follows the approximation, not exact `1 / sqrt(x)`.

The bounded domain keeps the binary32 input positive, finite, and normal. It also distinguishes this Go version from [`fast_inverse_square_root`](../fast_inverse_square_root/README.md), whose pinned PHP source uses one correction with binary64 arithmetic.

## Workload and build

[`workload.json`](workload.json) covers the bounds and representative values, plus zero, negative, and out-of-range inputs. Outputs are compared with relative tolerance `1e-12`.

```sh
python3 benchmarks/build_abi.py --family float64_unary --algorithm fast_inverse_sqrt_go --language rust
python3 benchmarks/run_float64_unary.py --build-manifest build/float64_unary/f/fast_inverse_sqrt_go/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/f/fast_inverse_sqrt_go.c`](../../../c/f/fast_inverse_sqrt_go.c) |
| C3 | [`c3/f/fast_inverse_sqrt_go.c3`](../../../c3/f/fast_inverse_sqrt_go.c3) |
| C++ | [`cpp/f/fast_inverse_sqrt_go.cpp`](../../../cpp/f/fast_inverse_sqrt_go.cpp) |
| Elisa | [`elisa/f/fast_inverse_sqrt_go.elisa`](../../../elisa/f/fast_inverse_sqrt_go.elisa) |
| Nim | [`nim/f/fast_inverse_sqrt_go.nim`](../../../nim/f/fast_inverse_sqrt_go.nim) |
| Odin | [`odin/f/fast_inverse_sqrt_go.odin`](../../../odin/f/fast_inverse_sqrt_go.odin) |
| Rust | [`rust/f/fast_inverse_sqrt_go.rs`](../../../rust/f/fast_inverse_sqrt_go.rs) |
| V | [`v/f/fast_inverse_sqrt_go.v`](../../../v/f/fast_inverse_sqrt_go.v) |
| Zig | [`zig/f/fast_inverse_sqrt_go.zig`](../../../zig/f/fast_inverse_sqrt_go.zig) |

## Pinned source

- Go [`fast_inverse_sqrt.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/binary/fast_inverse_sqrt.go)
