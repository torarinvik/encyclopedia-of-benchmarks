# Hexadecimal to binary

Convert an ASCII hexadecimal string to the binary text returned by the pinned Java `HexaDecimalToBinary.convert` method.

## Contract

- The `i64_array_bytes_output` input contains an optional leading `+` or `-`, followed by 1 to 64 ASCII hexadecimal digits, one character code per array element. Uppercase and lowercase letters are accepted; leading zeroes are allowed.
- Valid values match Java's signed-int parse range: `-2^31..2^31-1`. Invalid digits, a sign without digits, empty or overlength input, and signed-int overflow return `-1`.
- Nonnegative output is the binary representation padded on the left to at least 8 characters. Zero returns `00000000`; values above 255 use the full binary representation. Negative values use Java's 32-bit two's-complement representation.
- Insufficient output capacity returns `-2` without writing. `workspace.bytes` is 32; valid outputs are 8 to 32 bytes.

## Pinned source

The benchmark follows Java [`HexaDecimalToBinary.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/conversions/HexaDecimalToBinary.java), which parses the whole string with `Integer.parseInt(hex, 16)`, converts the signed Java `int` with `Integer.toBinaryString`, and pads positive results to a minimum width of eight. This differs from [`hexadecimal_to_binary`](../hexadecimal_to_binary/README.md), which encodes each numeric nibble and preserves its per-digit width.

[`workload.json`](workload.json) covers zero, optional signs, negative two's-complement output, leading zeroes, byte-width boundaries, signed-int limits, malformed strings, overflow, and short output buffers.

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm hexa_decimal_to_binary --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm hexa_decimal_to_binary
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm hexa_decimal_to_binary
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/h/hexa_decimal_to_binary.c`](../../../c/h/hexa_decimal_to_binary.c) |
| C3 | [`c3/h/hexa_decimal_to_binary.c3`](../../../c3/h/hexa_decimal_to_binary.c3) |
| C++ | [`cpp/h/hexa_decimal_to_binary.cpp`](../../../cpp/h/hexa_decimal_to_binary.cpp) |
| Elisa | [`elisa/h/hexa_decimal_to_binary.elisa`](../../../elisa/h/hexa_decimal_to_binary.elisa) |
| Nim | [`nim/h/hexa_decimal_to_binary.nim`](../../../nim/h/hexa_decimal_to_binary.nim) |
| Odin | [`odin/h/hexa_decimal_to_binary.odin`](../../../odin/h/hexa_decimal_to_binary.odin) |
| Rust | [`rust/h/hexa_decimal_to_binary.rs`](../../../rust/h/hexa_decimal_to_binary.rs) |
| V | [`v/h/hexa_decimal_to_binary.v`](../../../v/h/hexa_decimal_to_binary.v) |
| Zig | [`zig/h/hexa_decimal_to_binary.zig`](../../../zig/h/hexa_decimal_to_binary.zig) |
