# One-based hexagonal numbers

Return the first `n` positive-index hexagonal numbers from the pinned TypeScript source, using `h_i = i(2i - 1)` for indices `i = 1, 2, ..., n`. An input of 0 returns an empty list.

## Contract

- Input is a signed 64-bit integer from 0 through 1,024.
- Output is `n` signed 64-bit values in little-endian byte order, beginning with 1 when `n > 0`.
- Inputs outside the range return `-1`; an output buffer shorter than `8 * n` bytes returns `-2`. For `n=0`, the result is 0 and the output is empty.
- The formula is exact throughout the bounded input range.

The pinned Python implementation [`hexagonal_numbers`](../hexagonal_numbers/README.md) instead returns values at indices `0..length-1`, including 0. This package keeps the TypeScript source's one-based behavior distinct.

[`workload.json`](workload.json) covers the empty sequence, short sequences, the TypeScript example, the maximum supported length, and invalid lengths.

| Language | Source |
| --- | --- |
| C | [`c/h/hexagonal_numbers_one_based.c`](../../../c/h/hexagonal_numbers_one_based.c) |
| C3 | [`c3/h/hexagonal_numbers_one_based.c3`](../../../c3/h/hexagonal_numbers_one_based.c3) |
| C++ | [`cpp/h/hexagonal_numbers_one_based.cpp`](../../../cpp/h/hexagonal_numbers_one_based.cpp) |
| Elisa | [`elisa/h/hexagonal_numbers_one_based.elisa`](../../../elisa/h/hexagonal_numbers_one_based.elisa) |
| Nim | [`nim/h/hexagonal_numbers_one_based.nim`](../../../nim/h/hexagonal_numbers_one_based.nim) |
| Odin | [`odin/h/hexagonal_numbers_one_based.odin`](../../../odin/h/hexagonal_numbers_one_based.odin) |
| Rust | [`rust/h/hexagonal_numbers_one_based.rs`](../../../rust/h/hexagonal_numbers_one_based.rs) |
| V | [`v/h/hexagonal_numbers_one_based.v`](../../../v/h/hexagonal_numbers_one_based.v) |
| Zig | [`zig/h/hexagonal_numbers_one_based.zig`](../../../zig/h/hexagonal_numbers_one_based.zig) |

Pinned source: [TheAlgorithms/TypeScript `hexagonal_numbers.ts`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/maths/series/hexagonal_numbers.ts).
