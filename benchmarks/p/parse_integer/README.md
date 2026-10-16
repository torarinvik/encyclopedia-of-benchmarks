# Strict decimal string to integer parsing

## Contract

Parse one ASCII string represented as an `i64_array_scalar` byte array. The accepted byte values are ASCII `0` through `127`; input length is 1 through 64. A leading `+` or `-` is optional, and every following byte must be an ASCII decimal digit. A sign alone returns 0 because the pinned Java loop has no digit-count check. Empty strings, non-ASCII bytes, and any malformed character return `INT64_MIN` as the benchmark invalid-input sentinel.

The pinned method accumulates in Java `int`, so each `number = number * 10 + digit` step wraps modulo 2³², then it applies unary negation in the same 32-bit type when the first character is `-`. The ports reproduce that wraparound and sign-extend the result to signed 64-bit ABI output. For ASCII digits, Java's `Character.isDigit` check and subtraction of `'0'` agree. Unicode decimal digits are outside the byte contract.

This strict whole-string parser differs from [`string_to_integer`](../../s/string_to_integer/README.md) and [`c_atoi_str_to_integer`](../../c/c_atoi_str_to_integer/README.md), which skip leading whitespace, parse only an initial digit prefix, and clamp to signed 32-bit bounds. Here whitespace and trailing characters are malformed, and overflow wraps as Java `int` arithmetic.

## Source

- [TheAlgorithms/Java `ParseInteger.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/ParseInteger.java), pinned at `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.

## Workload and implementations

[`workload.json`](workload.json) covers signed and unsigned values, both int32 edges, Java overflow wrapping, sign-only source behavior, and malformed input.

| Language | Implementation |
| --- | --- |
| C | [`c/p/parse_integer.c`](../../../c/p/parse_integer.c) |
| C3 | [`c3/p/parse_integer.c3`](../../../c3/p/parse_integer.c3) |
| C++ | [`cpp/p/parse_integer.cpp`](../../../cpp/p/parse_integer.cpp) |
| Elisa | [`elisa/p/parse_integer.elisa`](../../../elisa/p/parse_integer.elisa) |
| Nim | [`nim/p/parse_integer.nim`](../../../nim/p/parse_integer.nim) |
| Odin | [`odin/p/parse_integer.odin`](../../../odin/p/parse_integer.odin) |
| Rust | [`rust/p/parse_integer.rs`](../../../rust/p/parse_integer.rs) |
| V | [`v/p/parse_integer.v`](../../../v/p/parse_integer.v) |
| Zig | [`zig/p/parse_integer.zig`](../../../zig/p/parse_integer.zig) |

All implementations use the `i64_array_scalar` ABI and export `parse_integer`.
