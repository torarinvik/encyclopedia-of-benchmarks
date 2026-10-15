# Decimal to binary, recursive decimal-digit encoding

## Contract

Convert a nonnegative integer to binary by recursive division, then return the
binary digits as a decimal integer. For example, input `5` returns `101`, and
input `10` returns `1010`. Input zero returns `0`.

The supported input range is `0..=1023`. This keeps every decimal-coded result
within the signed 32-bit return range used by the pinned C source: `1023`
returns `1111111111`, while the next input would produce `10000000000`, which
does not fit in a C `int`. Inputs outside the range return `-1`.

The exported C ABI entry point is:

```c
int64_t decimal_to_binary_recursion(int64_t value);
```

## Relation to `decimal_to_binary`

The existing [`decimal_to_binary`](../decimal_to_binary/README.md) benchmark
returns most-significant-first ASCII digits in a caller-owned buffer for the
full nonnegative signed 64-bit range. This variant preserves the pinned
recursive recurrence and its numeric return representation, so it is tracked
as a separate algorithm variant rather than an alias.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/d/decimal_to_binary_recursion.c`](../../../c/d/decimal_to_binary_recursion.c) |
| C3 | [`c3/d/decimal_to_binary_recursion.c3`](../../../c3/d/decimal_to_binary_recursion.c3) |
| C++ | [`cpp/d/decimal_to_binary_recursion.cpp`](../../../cpp/d/decimal_to_binary_recursion.cpp) |
| Elisa | [`elisa/d/decimal_to_binary_recursion.elisa`](../../../elisa/d/decimal_to_binary_recursion.elisa) |
| Nim | [`nim/d/decimal_to_binary_recursion.nim`](../../../nim/d/decimal_to_binary_recursion.nim) |
| Odin | [`odin/d/decimal_to_binary_recursion.odin`](../../../odin/d/decimal_to_binary_recursion.odin) |
| Rust | [`rust/d/decimal_to_binary_recursion.rs`](../../../rust/d/decimal_to_binary_recursion.rs) |
| V | [`v/d/decimal_to_binary_recursion.v`](../../../v/d/decimal_to_binary_recursion.v) |
| Zig | [`zig/d/decimal_to_binary_recursion.zig`](../../../zig/d/decimal_to_binary_recursion.zig) |

## TheAlgorithms source

- [C `decimal_to_binary_recursion.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/conversions/decimal_to_binary_recursion.c)
