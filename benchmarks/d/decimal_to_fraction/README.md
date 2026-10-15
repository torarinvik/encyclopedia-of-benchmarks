# Decimal to fraction

Convert a bounded decimal value to a reduced signed numerator and positive denominator. This package follows the common behavior of the pinned Python and Rust sources: convert the input to binary64, detect whether it is integral, determine the number of decimal digits from its ordinary shortest string form, scale by a power of ten, truncate the scaled binary64 toward zero, and reduce by the greatest common divisor. Integer-valued inputs return denominator 1.

## Contract

The `i64_array_bytes_output` input is `[mantissa, decimal_places]`, representing `mantissa / 10^decimal_places`. `decimal_places` is 0 through 4, the represented value is in `[-1,000,000, 1,000,000]`, and `mantissa` must be divisible by `5^decimal_places`. This last condition restricts inputs to decimal values exactly representable in binary64. It keeps the Python and Rust shortest-decimal formatting aligned and prevents the source's integer cast from truncating a binary rounding artifact. Non-exact binary decimals such as `0.1` are outside the contract.

For a noninteger value, the supported input's decimal digit count is `decimal_places` with trailing decimal zeroes removed, matching the ordinary shortest string form for this bounded exact subset. The implementation still performs the source-style floating conversion, precision-based scaling, and truncating cast before reducing the fraction; it does not simplify the input pair as an exact rational first. Negative fractional values retain a negative numerator, for example `-2.5` becomes `(-5, 2)`. Zero and integers use denominator 1.

Return 16 bytes containing the signed numerator and then the positive denominator, each as little-endian signed 64-bit integers. Malformed or out-of-domain input returns `-1`; insufficient output capacity returns `-2`. The pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/decimal_to_fraction.py) accepts floats and numeric strings, while the pinned [Rust source](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/decimal_to_fraction.rs) accepts `f64`. This ABI represents their common bounded numeric behavior; parsing arbitrary strings and arbitrary IEEE-754 values is outside this contract.

[`workload.json`](workload.json) covers zero, positive and negative fractions, integers, trailing decimal zeroes, and the magnitude bounds, along with malformed and excluded inexact decimals. The existing decimal/base conversion benchmarks convert integer digits between bases and do not reduce a decimal value to a rational pair, so this is a separate operation. The shared `i64_array_bytes_output` runner needs a source-oracle branch for this algorithm before recording can run.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/d/decimal_to_fraction.c`](../../../c/d/decimal_to_fraction.c) |
| C3 | [`c3/d/decimal_to_fraction.c3`](../../../c3/d/decimal_to_fraction.c3) |
| C++ | [`cpp/d/decimal_to_fraction.cpp`](../../../cpp/d/decimal_to_fraction.cpp) |
| Elisa | [`elisa/d/decimal_to_fraction.elisa`](../../../elisa/d/decimal_to_fraction.elisa) |
| Nim | [`nim/d/decimal_to_fraction.nim`](../../../nim/d/decimal_to_fraction.nim) |
| Odin | [`odin/d/decimal_to_fraction.odin`](../../../odin/d/decimal_to_fraction.odin) |
| Rust | [`rust/d/decimal_to_fraction.rs`](../../../rust/d/decimal_to_fraction.rs) |
| V | [`v/d/decimal_to_fraction.v`](../../../v/d/decimal_to_fraction.v) |
| Zig | [`zig/d/decimal_to_fraction.zig`](../../../zig/d/decimal_to_fraction.zig) |
