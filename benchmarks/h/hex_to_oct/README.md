# Hexadecimal to octal

Convert an ASCII hexadecimal string to the signed Java `int` returned by the pinned `HexToOct.hexToOctal` method.

## Contract

- The `i64_array_scalar` input contains 0 to 8 ASCII hexadecimal digits, one character code per array element. Uppercase and lowercase digits are accepted; empty input returns 0.
- Hex accumulation follows Java signed-32-bit wraparound. The source's decimal-to-octal loop returns 0 for zero or negative intermediate values.
- The source builds the octal digits as a base-10 integer and also wraps each multiplication/addition to signed 32-bit. The benchmark preserves that result, including values whose octal digit integer overflows.
- The pinned Java lookup uses `String.indexOf`, which maps an unknown character to `-1`; the benchmark deliberately treats non-hexadecimal input as malformed and returns `-2147483649` instead, outside the signed-32-bit result range. Input longer than 8 characters returns the same sentinel.

## Pinned source

The benchmark follows Java [`HexToOct.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/conversions/HexToOct.java). Its two-stage conversion is distinct from [`hexadecimal_to_octal`](../hexadecimal_to_octal/README.md), which accepts numeric nibbles and returns canonical octal text.

[`workload.json`](workload.json) covers empty and zero input, case-insensitive digits, source examples, signed-32-bit accumulation boundaries, octal output overflow, malformed characters, and overlength input.

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm hex_to_oct --language rust
python3 benchmarks/run_i64_array_scalar.py --algorithm hex_to_oct
python3 benchmarks/verify_i64_array_scalar.py --algorithm hex_to_oct
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/h/hex_to_oct.c`](../../../c/h/hex_to_oct.c) |
| C3 | [`c3/h/hex_to_oct.c3`](../../../c3/h/hex_to_oct.c3) |
| C++ | [`cpp/h/hex_to_oct.cpp`](../../../cpp/h/hex_to_oct.cpp) |
| Elisa | [`elisa/h/hex_to_oct.elisa`](../../../elisa/h/hex_to_oct.elisa) |
| Nim | [`nim/h/hex_to_oct.nim`](../../../nim/h/hex_to_oct.nim) |
| Odin | [`odin/h/hex_to_oct.odin`](../../../odin/h/hex_to_oct.odin) |
| Rust | [`rust/h/hex_to_oct.rs`](../../../rust/h/hex_to_oct.rs) |
| V | [`v/h/hex_to_oct.v`](../../../v/h/hex_to_oct.v) |
| Zig | [`zig/h/hex_to_oct.zig`](../../../zig/h/hex_to_oct.zig) |
