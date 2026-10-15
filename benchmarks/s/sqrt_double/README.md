# Double-precision square root by bisection

## Contract

The function accepts one finite binary64 input. Zero returns zero; inputs in `[1/256, 64]` return an approximate nonnegative square root. Negative inputs, positive inputs below `1/256`, and inputs above `64` return `-1`.

The exported C ABI entry point is:

```c
double sqrt_double(double value);
```

For inputs from one through 64, the implementation bisects `[0, value]`. Each step computes `mid = (low + high) / 2`; if `mid * mid > value`, it sets `high = mid`. Otherwise it returns `mid` when `value - mid * mid < 1e-12`, or sets `low = mid`. For values strictly between zero and one, it recursively evaluates the reciprocal and returns its reciprocal. This preserves the pinned source's update order, lower-side stopping rule, and reciprocal branch. The bounded positive domain limits the reciprocal input to at most 256 and keeps the squared-residual stopping rule well above binary64 rounding noise.

The returned value is compared with the binary64 square root using relative tolerance `1e-12`. This is separate from the source's internal squared-residual threshold of `1e-12`.

This benchmark measures the bisection method. The existing [`square_root`](../square_root/README.md) benchmark uses Newton iteration, and [`square_root_binary_search`](../square_root_binary_search/README.md) returns an integer floor root.

## Workload and recording

[`workload.json`](workload.json) covers zero, the lower positive boundary, the reciprocal path, values around one, representative roots, the upper boundary, and out-of-domain inputs. Build with the `float64_unary` ABI family and record with:

```sh
python3 benchmarks/build_abi.py --family float64_unary --algorithm sqrt_double --language rust
python3 benchmarks/run_float64_unary.py --build-manifest build/float64_unary/s/sqrt_double/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/sqrt_double.c`](../../../c/s/sqrt_double.c) |
| C3 | [`c3/s/sqrt_double.c3`](../../../c3/s/sqrt_double.c3) |
| C++ | [`cpp/s/sqrt_double.cpp`](../../../cpp/s/sqrt_double.cpp) |
| Elisa | [`elisa/s/sqrt_double.elisa`](../../../elisa/s/sqrt_double.elisa) |
| Nim | [`nim/s/sqrt_double.nim`](../../../nim/s/sqrt_double.nim) |
| Odin | [`odin/s/sqrt_double.odin`](../../../odin/s/sqrt_double.odin) |
| Rust | [`rust/s/sqrt_double.rs`](../../../rust/s/sqrt_double.rs) |
| V | [`v/s/sqrt_double.v`](../../../v/s/sqrt_double.v) |
| Zig | [`zig/s/sqrt_double.zig`](../../../zig/s/sqrt_double.zig) |

## TheAlgorithms sources

- [C++ `sqrt_double.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/sqrt_double.cpp)
- [Additional C++ `sqrt_double.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/sqrt_double.cpp)
