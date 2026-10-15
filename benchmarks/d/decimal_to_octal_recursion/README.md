# Decimal to octal, recursive decimal-digit encoding

## Contract

Convert a nonnegative integer to octal by recursive division, then return the octal digits as a decimal integer. For example, input `8` returns `10`, input `342` returns `526`, and input zero returns `0`.

The accepted input range is `0..=295,600,127`. The pinned C source returns the packed digits as a signed 32-bit `int`; at the upper bound the result is `2,147,477,777`, while the next input produces `2,147,500,000`, which exceeds `INT32_MAX`. Inputs outside the range return `-1`.

The scalar ABI is `int64_t decimal_to_octal_recursion(int64_t value)`. Ports retain the recursive divide-by-eight recurrence while using the wider ABI for a consistent cross-language boundary.

## Relation to `decimal_to_octal`

The existing [`decimal_to_octal`](../decimal_to_octal/README.md) benchmark returns most-significant-first ASCII digits in a caller-owned byte buffer. This variant returns the same digits packed as a numeric decimal integer and preserves the recursive recurrence from the C source, so it has a distinct contract and result representation.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/d/decimal_to_octal_recursion.c`](../../../c/d/decimal_to_octal_recursion.c) |
| C3 | [`c3/d/decimal_to_octal_recursion.c3`](../../../c3/d/decimal_to_octal_recursion.c3) |
| C++ | [`cpp/d/decimal_to_octal_recursion.cpp`](../../../cpp/d/decimal_to_octal_recursion.cpp) |
| Elisa | [`elisa/d/decimal_to_octal_recursion.elisa`](../../../elisa/d/decimal_to_octal_recursion.elisa) |
| Nim | [`nim/d/decimal_to_octal_recursion.nim`](../../../nim/d/decimal_to_octal_recursion.nim) |
| Odin | [`odin/d/decimal_to_octal_recursion.odin`](../../../odin/d/decimal_to_octal_recursion.odin) |
| Rust | [`rust/d/decimal_to_octal_recursion.rs`](../../../rust/d/decimal_to_octal_recursion.rs) |
| V | [`v/d/decimal_to_octal_recursion.v`](../../../v/d/decimal_to_octal_recursion.v) |
| Zig | [`zig/d/decimal_to_octal_recursion.zig`](../../../zig/d/decimal_to_octal_recursion.zig) |

## TheAlgorithms source

- [C `decimal_to_octal_recursion.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/conversions/decimal_to_octal_recursion.c)
