# Fast inverse square root

Computes the Quake-style fast inverse square root using one bit-hack seed and one Newton correction.

## Contract

- Uses the unary `float64_unary` ABI: `double fast_inverse_square_root(double x)`.
- Inputs must be finite and in `[1e-6, 1e6]`. This keeps the float32 seed finite, normal, and positive.
- Return the source approximation using the binary32 seed and binary64 correction described below. The workload expects this approximation, not an exact `1/sqrt(x)` result.
- Return `-1.0` for zero, negative, non-finite, or out-of-range input.
- Results are compared with relative tolerance `1e-12`.

## Source semantics

This follows the pinned [TheAlgorithms PHP `FastInverseSquareRoot.php`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Maths/FastInverseSquareRoot.php). PHP `pack('f')` rounds the input to IEEE-754 binary32, and `unpack('l')` reads those same bytes as a signed 32-bit integer. The source computes `0x5f3759df - (bits >> 1)`, reinterprets the result as binary32 `y`, then returns `y * (1.5 - 0.5 * x * y * y)`. In the selected positive domain the seed bits are nonnegative, so signed right shift matches the expected logical shift. The correction uses the original input `x` and PHP floating-point arithmetic, rather than the rounded binary32 value.

The ports preserve the float32 bit reinterpretations, magic constant, signed shift, and correction operation order. Elisa reconstructs the binary32 exponent and fraction arithmetically because the language has no bit reinterpret cast. PHP does not validate its argument; the positive finite benchmark domain excludes unsupported values and maps invalid ABI inputs to `-1.0`.

## Workload and build

[`workload.json`](workload.json) covers the source approximation at representative inputs and both bounds, plus invalid values. Build and record with the `float64_unary` ABI:

```sh
python3 benchmarks/build_abi.py --family float64_unary --algorithm fast_inverse_square_root --language rust
python3 benchmarks/run_float64_unary.py --build-manifest build/float64_unary/f/fast_inverse_square_root/rust/build.json
```

The nine implementations are in `c/f/fast_inverse_square_root.c`, `c3/f/fast_inverse_square_root.c3`, `cpp/f/fast_inverse_square_root.cpp`, `elisa/f/fast_inverse_square_root.elisa`, `nim/f/fast_inverse_square_root.nim`, `odin/f/fast_inverse_square_root.odin`, `rust/f/fast_inverse_square_root.rs`, `v/f/fast_inverse_square_root.v`, and `zig/f/fast_inverse_square_root.zig`.
