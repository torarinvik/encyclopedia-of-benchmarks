# Power for huge numbers

Compute an exact decimal representation of `base^exponent` using repeated multiplication of a decimal digit array, following the pinned TheAlgorithms/C-Plus-Plus implementation.

## Contract

- ABI: signed i64 array to byte output. Input is `[base, exponent]`, with `1 <= base <= 10,000` and `0 <= exponent <= 128`.
- The result is the unsigned base-10 numeral only: no source CLI label, sign, whitespace, or NUL terminator. Exponent zero returns `1`.
- Invalid shape or values return `-1`. Insufficient output capacity returns `-2` without writing.
- The largest supported result is `10,000^128 = 10^512`, which has 513 decimal digits. The workspace is 513 bytes. Each decimal digit multiplication and carry fits a 32-bit unsigned value.

## Source and workload

This package follows the repeated decimal-array multiplication algorithm in [TheAlgorithms/C-Plus-Plus `power_for_huge_numbers.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/power_for_huge_numbers.cpp). The C-Plus-Plus-1 pin at `0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680` has the same source bytes. The source's CLI label (`x^n = `) is omitted because this ABI returns the algorithm's numeric result.

The bounded workload includes zero and maximum exponents, base one, a 513-digit result, malformed inputs, and a short output buffer. The independent Python oracle uses arbitrary-precision integer exponentiation.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/power_for_huge_numbers.c`](../../../c/p/power_for_huge_numbers.c) |
| C3 | [`c3/p/power_for_huge_numbers.c3`](../../../c3/p/power_for_huge_numbers.c3) |
| C++ | [`cpp/p/power_for_huge_numbers.cpp`](../../../cpp/p/power_for_huge_numbers.cpp) |
| Elisa | [`elisa/p/power_for_huge_numbers.elisa`](../../../elisa/p/power_for_huge_numbers.elisa) |
| Nim | [`nim/p/power_for_huge_numbers.nim`](../../../nim/p/power_for_huge_numbers.nim) |
| Odin | [`odin/p/power_for_huge_numbers.odin`](../../../odin/p/power_for_huge_numbers.odin) |
| Rust | [`rust/p/power_for_huge_numbers.rs`](../../../rust/p/power_for_huge_numbers.rs) |
| V | [`v/p/power_for_huge_numbers.v`](../../../v/p/power_for_huge_numbers.v) |
| Zig | [`zig/p/power_for_huge_numbers.zig`](../../../zig/p/power_for_huge_numbers.zig) |
