# Bailey–Borwein–Plouffe hexadecimal digit extraction

The pinned Python routine extracts one hexadecimal digit of π after the radix point. Digit positions are one based: position 1 is the first digit. It combines four BBP subsums with coefficients `4, -2, -1, -1`, then converts the first hexadecimal digit of the fractional part to its symbol.

## Contract

- Input is a signed 64-bit digit position from 1 through 10.
- The source's default precision is fixed at 1000 terms in each tail sum.
- Return the extracted hexadecimal digit as its numeric nibble: `0..9` or `10..15` for `a..f`.
- Return `-1` outside the supported position range.

The pinned source returns a one-character lowercase hexadecimal string. The scalar ABI uses an integer result, so the benchmark maps that character to its nibble value; this preserves the digit symbol while avoiding a custom string runner. The workload is about hexadecimal digit extraction, not a numeric approximation of π. The position bound keeps the direct summations small while covering the source's documented first-ten-digit example.

For each subsum, indices below the requested position use exact modular exponentiation `pow(16, position - 1 - index, denominator)`. The remaining 1000 terms use the ordinary floating power and are accumulated in order. The ports preserve the BBP expression and fixed default precision.

## Workload

[`workload.json`](workload.json) covers positions 1 through 10, matching the pinned source example `243f6a8885`, plus invalid signed positions.

The scalar ABI is `int64_t bailey_borwein_plouffe(int64_t digit_position)`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/bailey_borwein_plouffe.c`](../../../c/b/bailey_borwein_plouffe.c) |
| C3 | [`c3/b/bailey_borwein_plouffe.c3`](../../../c3/b/bailey_borwein_plouffe.c3) |
| C++ | [`cpp/b/bailey_borwein_plouffe.cpp`](../../../cpp/b/bailey_borwein_plouffe.cpp) |
| Elisa | [`elisa/b/bailey_borwein_plouffe.elisa`](../../../elisa/b/bailey_borwein_plouffe.elisa) |
| Nim | [`nim/b/bailey_borwein_plouffe.nim`](../../../nim/b/bailey_borwein_plouffe.nim) |
| Odin | [`odin/b/bailey_borwein_plouffe.odin`](../../../odin/b/bailey_borwein_plouffe.odin) |
| Rust | [`rust/b/bailey_borwein_plouffe.rs`](../../../rust/b/bailey_borwein_plouffe.rs) |
| V | [`v/b/bailey_borwein_plouffe.v`](../../../v/b/bailey_borwein_plouffe.v) |
| Zig | [`zig/b/bailey_borwein_plouffe.zig`](../../../zig/b/bailey_borwein_plouffe.zig) |

## Upstream source

- [TheAlgorithms/Python `bailey_borwein_plouffe.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/bailey_borwein_plouffe.py)
