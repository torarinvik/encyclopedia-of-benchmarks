# Trigonometric functions

This benchmark covers the eight public sine, cosine, tangent, and cotangent wrappers from the pinned Rust source. It follows the source's Maclaurin series and repeated period reduction, including its six-decimal rounding before tangent and cotangent division.

## Contract

Input is exactly three float64 values `[selector, x, tolerance]` and each valid call returns one float64 output. Selector must be an exact finite integer from 0 through 7:

| Selector | Operation |
|---:|---|
| 0 | Sine, radians |
| 1 | Cosine, radians |
| 2 | Sine, degrees |
| 3 | Cosine, degrees |
| 4 | Tangent, radians |
| 5 | Cotangent, radians |
| 6 | Tangent, degrees |
| 7 | Cotangent, degrees |

Finite `x` is bounded to `[-10,000, 10,000]`; tolerance is finite and in `[1e-9, 1e-2]`. A malformed length, selector, finite `x` outside the bound, or invalid tolerance returns `-1` with no output. For a valid selector and tolerance, non-finite `x` returns one NaN, matching the source's invalid-argument behavior.

The series repeatedly adds or subtracts `2π` until the value is within one period. It accumulates the sine or cosine Maclaurin terms until the difference between consecutive partial sums is no greater than the input tolerance, then rounds the result to six decimal places. Degree variants first convert `x` with `x * π / 180`. Tangent divides the rounded sine by the rounded cosine; cotangent divides the rounded cosine by the rounded sine. If that rounded denominator is zero, the result is NaN. Otherwise the quotient is returned without additional rounding.

The bounded period-reduced domain and minimum tolerance keep the source series within its signed 128-bit factorial range. Output comparison uses absolute tolerance `1e-6` and relative tolerance `1e-12`. The shared ABI returns `-2` for a null output pointer or insufficient output capacity.

[`workload.json`](workload.json) covers all selectors, negative and multi-period inputs, tolerance endpoints, invalid finite inputs, and rounded-zero denominators. The verifier also checks non-finite `x` values. The independent oracle is [`trig_functions_oracle.py`](../../trig_functions_oracle.py).

Pinned source: [TheAlgorithms/Rust `trig_functions.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/trig_functions.rs).

## Implementations

| Language | Port |
|---|---|
| C | [`c/t/trig_functions.c`](../../../c/t/trig_functions.c) |
| C3 | [`c3/t/trig_functions.c3`](../../../c3/t/trig_functions.c3) |
| C++ | [`cpp/t/trig_functions.cpp`](../../../cpp/t/trig_functions.cpp) |
| Elisa | [`elisa/t/trig_functions.elisa`](../../../elisa/t/trig_functions.elisa) |
| Nim | [`nim/t/trig_functions.nim`](../../../nim/t/trig_functions.nim) |
| Odin | [`odin/t/trig_functions.odin`](../../../odin/t/trig_functions.odin) |
| Rust | [`rust/t/trig_functions.rs`](../../../rust/t/trig_functions.rs) |
| V | [`v/t/trig_functions.v`](../../../v/t/trig_functions.v) |
| Zig | [`zig/t/trig_functions.zig`](../../../zig/t/trig_functions.zig) |
