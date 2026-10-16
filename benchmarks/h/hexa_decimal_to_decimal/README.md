# Hexadecimal string to decimal int

Convert an ASCII hexadecimal string to the signed 32-bit result produced by the pinned Java method.

## Contract

- The `i64_array_scalar` input contains one ASCII character code per string character, in order. Valid characters are `0`–`9`, `A`–`F`, and `a`–`f`.
- The empty string is valid and returns 0, matching the source loop. Nonempty inputs have at most 64 characters; a 65-value fixture is parseable to exercise the length guard.
- The source accumulates into a Java `int`, so arithmetic wraps modulo 2^32 and the returned value is interpreted as signed 32-bit. The ABI sign-extends that result to i64.
- Malformed length or any non-hexadecimal/non-ASCII code returns `-2147483649`, outside the source result range, as the benchmark invalid-input result.
- The Java method uppercases the string before looking up digits. The ports implement equivalent ASCII case-insensitive decoding for this bounded contract.

## Pinned source

The benchmark follows Java [`HexaDecimalToDecimal.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/conversions/HexaDecimalToDecimal.java), whose `getHexaToDec` scans the hexadecimal string left to right and updates `val = 16 * val + digit`.

[`workload.json`](workload.json) covers the empty input, mixed case, signed-int boundaries and wraparound, invalid characters, and the one-over-limit length.

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm hexa_decimal_to_decimal --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/h/hexa_decimal_to_decimal/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithms hexa_decimal_to_decimal
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/h/hexa_decimal_to_decimal.c`](../../../c/h/hexa_decimal_to_decimal.c) |
| C3 | [`c3/h/hexa_decimal_to_decimal.c3`](../../../c3/h/hexa_decimal_to_decimal.c3) |
| C++ | [`cpp/h/hexa_decimal_to_decimal.cpp`](../../../cpp/h/hexa_decimal_to_decimal.cpp) |
| Elisa | [`elisa/h/hexa_decimal_to_decimal.elisa`](../../../elisa/h/hexa_decimal_to_decimal.elisa) |
| Nim | [`nim/h/hexa_decimal_to_decimal.nim`](../../../nim/h/hexa_decimal_to_decimal.nim) |
| Odin | [`odin/h/hexa_decimal_to_decimal.odin`](../../../odin/h/hexa_decimal_to_decimal.odin) |
| Rust | [`rust/h/hexa_decimal_to_decimal.rs`](../../../rust/h/hexa_decimal_to_decimal.rs) |
| V | [`v/h/hexa_decimal_to_decimal.v`](../../../v/h/hexa_decimal_to_decimal.v) |
| Zig | [`zig/h/hexa_decimal_to_decimal.zig`](../../../zig/h/hexa_decimal_to_decimal.zig) |
