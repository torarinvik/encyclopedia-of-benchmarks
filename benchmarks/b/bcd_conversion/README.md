# Decimal integer to packed BCD

Convert a decimal integer in the pinned Java source's supported range to a packed binary-coded decimal integer. This package measures only `BcdConversion.decimalToBcd`; the companion decoder is outside the contract.

## Contract

- Input is one signed 64-bit integer in `[0, 9999]`.
- Process decimal digits from least significant to most significant. Place each digit in the next four-bit nibble, starting with the units digit in the low nibble. For example, `1234` returns the integer whose hexadecimal representation is `0x1234`; `1002` returns `0x1002`. Input `0` returns `0`, and leading decimal zeroes do not occupy high nibbles in the integer result.
- Invalid inputs return `-1`. The pinned Java method throws for values below zero or above 9999; `-1` is the benchmark's invalid-input mapping.
- The conversion takes `O(d)` time for `d` decimal digits and `O(1)` auxiliary space.

## Source and related algorithms

The pinned [Java `BcdConversion.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/bitmanipulation/BcdConversion.java) returns a packed `int`, placing the units digit in the least significant nibble. The separate [`binary_coded_decimal` benchmark](../binary_coded_decimal/README.md) returns a textual `0b`-prefixed bit representation with four printed bits per digit. Both encode decimal digits as BCD; this package preserves the Java API's packed integer result. The Java class also has a BCD-to-decimal decoder, which is not measured here.

## Workload and build

[`workload.json`](workload.json) covers zero, single and multiple digits, internal zeroes, the upper bound, and invalid values. All nine ports use the shared `scalar` ABI.

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm bcd_conversion --language rust
python3 benchmarks/run_scalar.py --build-manifest build/scalar/b/bcd_conversion/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/b/bcd_conversion.c`](../../../c/b/bcd_conversion.c) |
| C3 | [`c3/b/bcd_conversion.c3`](../../../c3/b/bcd_conversion.c3) |
| C++ | [`cpp/b/bcd_conversion.cpp`](../../../cpp/b/bcd_conversion.cpp) |
| Elisa | [`elisa/b/bcd_conversion.elisa`](../../../elisa/b/bcd_conversion.elisa) |
| Nim | [`nim/b/bcd_conversion.nim`](../../../nim/b/bcd_conversion.nim) |
| Odin | [`odin/b/bcd_conversion.odin`](../../../odin/b/bcd_conversion.odin) |
| Rust | [`rust/b/bcd_conversion.rs`](../../../rust/b/bcd_conversion.rs) |
| V | [`v/b/bcd_conversion.v`](../../../v/b/bcd_conversion.v) |
| Zig | [`zig/b/bcd_conversion.zig`](../../../zig/b/bcd_conversion.zig) |
