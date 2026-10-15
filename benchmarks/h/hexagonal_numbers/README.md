# Hexagonal numbers

Return the first `length` values of the pinned Python sequence, using `h_n = n(2n - 1)` for indices `n = 0, 1, ..., length - 1`. This source includes the initial value 0.

## Contract

- Input is a signed 64-bit integer from 1 through 1,024.
- Output is `length` signed 64-bit values in little-endian byte order. The first value is 0; the last is `h_(length-1)`.
- Inputs outside the range return `-1`; an output buffer shorter than `8 * length` bytes returns `-2`.
- The output uses the scalar-to-bytes ABI. The formula is exact throughout the bounded input range.

The pinned TypeScript implementation starts its loop at 1 and omits 0. That is a distinct one-based contract tracked as [`hexagonal_numbers_one_based`](../hexagonal_numbers_one_based/README.md), rather than folded into this Python behavior.

[`workload.json`](workload.json) covers short sequences, the pinned Python example, the maximum supported length, and invalid lengths.

| Language | Source |
| --- | --- |
| C | [`c/h/hexagonal_numbers.c`](../../../c/h/hexagonal_numbers.c) |
| C3 | [`c3/h/hexagonal_numbers.c3`](../../../c3/h/hexagonal_numbers.c3) |
| C++ | [`cpp/h/hexagonal_numbers.cpp`](../../../cpp/h/hexagonal_numbers.cpp) |
| Elisa | [`elisa/h/hexagonal_numbers.elisa`](../../../elisa/h/hexagonal_numbers.elisa) |
| Nim | [`nim/h/hexagonal_numbers.nim`](../../../nim/h/hexagonal_numbers.nim) |
| Odin | [`odin/h/hexagonal_numbers.odin`](../../../odin/h/hexagonal_numbers.odin) |
| Rust | [`rust/h/hexagonal_numbers.rs`](../../../rust/h/hexagonal_numbers.rs) |
| V | [`v/h/hexagonal_numbers.v`](../../../v/h/hexagonal_numbers.v) |
| Zig | [`zig/h/hexagonal_numbers.zig`](../../../zig/h/hexagonal_numbers.zig) |

Pinned source: [TheAlgorithms/Python `hexagonal_numbers.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/series/hexagonal_numbers.py).
