# One-based hexagonal numbers

Return the first `n` positive-index hexagonal numbers from the pinned TypeScript source, using `h_i = i(2i - 1)` for indices `i = 1, 2, ..., n`. An input of 0 returns an empty list.

## Contract

- Input is a signed 64-bit integer from 0 through 1,024.
- Output is `n` signed 64-bit values in little-endian byte order, beginning with 1 when `n > 0`.
- Inputs outside the range return `-1`; an output buffer shorter than `8 * n` bytes returns `-2`. For `n=0`, the result is 0 and the output is empty.
- The formula is exact throughout the bounded input range.

The pinned [Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/series/hexagonal_numbers.py)
returns the same formula at indices `0..length-1`, including zero. For its
former bounded contract `1 <= length <= 1024`, prepend zero to this
benchmark's first `length-1` terms; validate the original domain separately.
The zero-based duplicate package was removed.

[`workload.json`](workload.json) covers the empty sequence, short sequences, the TypeScript example, the maximum supported length, and invalid lengths.

| Language | Source |
| --- | --- |
| C | [`c/h/hexagonal_numbers_one_based.c`](../../../c/h/hexagonal_numbers_one_based.c) |
| C3 | [`c3/h/hexagonal_numbers_one_based.c3`](../../../c3/h/hexagonal_numbers_one_based.c3) |
| C++ | [`cpp/h/hexagonal_numbers_one_based.cpp`](../../../cpp/h/hexagonal_numbers_one_based.cpp) |
| Elisa | [`elisa/h/hexagonal_numbers_one_based.elisa`](../../../elisa/h/hexagonal_numbers_one_based.elisa) |
| Mojo | [`mojo/h/hexagonal_numbers_one_based.mojo`](../../../mojo/h/hexagonal_numbers_one_based.mojo) |
| Nim | [`nim/h/hexagonal_numbers_one_based.nim`](../../../nim/h/hexagonal_numbers_one_based.nim) |
| Odin | [`odin/h/hexagonal_numbers_one_based.odin`](../../../odin/h/hexagonal_numbers_one_based.odin) |
| Rust | [`rust/h/hexagonal_numbers_one_based.rs`](../../../rust/h/hexagonal_numbers_one_based.rs) |
| V | [`v/h/hexagonal_numbers_one_based.v`](../../../v/h/hexagonal_numbers_one_based.v) |
| Zig | [`zig/h/hexagonal_numbers_one_based.zig`](../../../zig/h/hexagonal_numbers_one_based.zig) |

Pinned source: [TheAlgorithms/TypeScript `hexagonal_numbers.ts`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/maths/series/hexagonal_numbers.ts).
