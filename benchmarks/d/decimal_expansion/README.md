# Decimal expansion

Expand a nonnegative fraction in a radix from 2 through 10 and report any repeating cycle. This follows the pinned JavaScript `decExp` routine for proper fractions and the `a == b` special case.

## Contract

The `i64_array_bytes_output` input is exactly `[numerator, denominator, base]`, with `0 <= numerator <= denominator <= 256` and `2 <= base <= 10`. A valid call returns the output byte count. Invalid input returns `-1`; a null output pointer or insufficient capacity returns `-2`.

The output is three little-endian signed 64-bit integers followed by one byte per fractional digit:

1. Integer part (`0` for a proper fraction, `1` when numerator equals denominator).
2. Fractional digit count.
3. First digit index in the repeating cycle, or `-1` when the expansion terminates or has no digits.
4. Fractional digits, each in `[0, base)`.

For zero numerator the source returns zero and no digits. For a nonzero proper fraction, long division emits digits until the remainder becomes zero or repeats. The denominator bound limits the digit sequence to at most 255 bytes.

## Workload

[`workload.json`](workload.json) covers terminating and repeating expansions in several bases, zero and one, invalid bounds, malformed lengths, and short output capacity.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/d/decimal_expansion.c`](../../../c/d/decimal_expansion.c) |
| C3 | [`c3/d/decimal_expansion.c3`](../../../c3/d/decimal_expansion.c3) |
| C++ | [`cpp/d/decimal_expansion.cpp`](../../../cpp/d/decimal_expansion.cpp) |
| Elisa | [`elisa/d/decimal_expansion.elisa`](../../../elisa/d/decimal_expansion.elisa) |
| Nim | [`nim/d/decimal_expansion.nim`](../../../nim/d/decimal_expansion.nim) |
| Odin | [`odin/d/decimal_expansion.odin`](../../../odin/d/decimal_expansion.odin) |
| Rust | [`rust/d/decimal_expansion.rs`](../../../rust/d/decimal_expansion.rs) |
| V | [`v/d/decimal_expansion.v`](../../../v/d/decimal_expansion.v) |
| Zig | [`zig/d/decimal_expansion.zig`](../../../zig/d/decimal_expansion.zig) |

## Pinned source

- JavaScript [`DecimalExpansion.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/DecimalExpansion.js)
