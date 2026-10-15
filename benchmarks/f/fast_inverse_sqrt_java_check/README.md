# Java fast inverse square root exact checks

## Contract

This package preserves the pinned Java class's two `inverseSqrt` overloads. The functions return whether the computed value equals the library result exactly; they do not return an inverse-square-root approximation.

Use `i64_array_scalar_call` with `[precision_mode, raw_positive_ieee754_bits]`. Mode `0` selects the binary32 overload and accepts positive normal finite binary32 values. Mode `1` selects the binary64 overload and accepts positive normal finite binary64 values. The return value is `1` for exact equality, `0` otherwise, and `-1` for invalid mode, bit pattern, or input length.

The binary32 overload uses the `0x5f3759df` seed and one Newton correction, then compares it with `1.0f / (float) Math.sqrt(number)`. The binary64 overload uses the `0x5fe6ec85e7de30da` seed, performs four Newton corrections, multiplies by the input, and compares with `1.0 / Math.sqrt(number)`. These exact-equality checks have different semantics from the Go and Python approximation candidates.

[`workload.json`](workload.json) includes representative inputs for both overloads, exact-equality outcomes, invalid modes, unsupported IEEE values, and malformed lengths.

The `i64_array_scalar` runner validates the positive-normal IEEE bit ranges and computes both overloads with their Java precision and operation order before checking exact equality.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar_call --algorithm fast_inverse_sqrt_java_check --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar_call/f/fast_inverse_sqrt_java_check/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/f/fast_inverse_sqrt_java_check.c`](../../../c/f/fast_inverse_sqrt_java_check.c) |
| C3 | [`c3/f/fast_inverse_sqrt_java_check.c3`](../../../c3/f/fast_inverse_sqrt_java_check.c3) |
| C++ | [`cpp/f/fast_inverse_sqrt_java_check.cpp`](../../../cpp/f/fast_inverse_sqrt_java_check.cpp) |
| Elisa | [`elisa/f/fast_inverse_sqrt_java_check.elisa`](../../../elisa/f/fast_inverse_sqrt_java_check.elisa) |
| Nim | [`nim/f/fast_inverse_sqrt_java_check.nim`](../../../nim/f/fast_inverse_sqrt_java_check.nim) |
| Odin | [`odin/f/fast_inverse_sqrt_java_check.odin`](../../../odin/f/fast_inverse_sqrt_java_check.odin) |
| Rust | [`rust/f/fast_inverse_sqrt_java_check.rs`](../../../rust/f/fast_inverse_sqrt_java_check.rs) |
| V | [`v/f/fast_inverse_sqrt_java_check.v`](../../../v/f/fast_inverse_sqrt_java_check.v) |
| Zig | [`zig/f/fast_inverse_sqrt_java_check.zig`](../../../zig/f/fast_inverse_sqrt_java_check.zig) |

## Pinned source

- Java [`FastInverseSqrt.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/FastInverseSqrt.java)
