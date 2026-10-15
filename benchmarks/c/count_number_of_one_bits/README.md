# Count number of one bits

The pinned Python source provides three ways to count set bits: Brian Kernighan's method, repeated modulo and shifting, and a lookup table over four bytes. This benchmark exposes each variant through a method selector and bounds the input to unsigned 32-bit values, the lookup method's documented domain.

## Contract

- The binary scalar ABI receives `[number, method]`.
- `number` is in `[0, 2^32 - 1]`; negative or larger values return `-1`.
- `method = 0` selects Brian Kernighan's algorithm, `1` selects modulo and right shift, and `2` selects the 8-bit lookup table.
- The lookup table is initialized during each call, as the pinned Python function creates it inside the selected method.
- Invalid method selectors return `-1`. Valid calls return the population count.

[`workload.json`](workload.json) runs each method on the source examples, zero, and both 32-bit boundaries.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/count_number_of_one_bits.c`](../../../c/c/count_number_of_one_bits.c) |
| C3 | [`c3/c/count_number_of_one_bits.c3`](../../../c3/c/count_number_of_one_bits.c3) |
| C++ | [`cpp/c/count_number_of_one_bits.cpp`](../../../cpp/c/count_number_of_one_bits.cpp) |
| Elisa | [`elisa/c/count_number_of_one_bits.elisa`](../../../elisa/c/count_number_of_one_bits.elisa) |
| Nim | [`nim/c/count_number_of_one_bits.nim`](../../../nim/c/count_number_of_one_bits.nim) |
| Odin | [`odin/c/count_number_of_one_bits.odin`](../../../odin/c/count_number_of_one_bits.odin) |
| Rust | [`rust/c/count_number_of_one_bits.rs`](../../../rust/c/count_number_of_one_bits.rs) |
| V | [`v/c/count_number_of_one_bits.v`](../../../v/c/count_number_of_one_bits.v) |
| Zig | [`zig/c/count_number_of_one_bits.zig`](../../../zig/c/count_number_of_one_bits.zig) |

## Upstream source

- [TheAlgorithms/Python `count_number_of_one_bits.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/bit_manipulation/count_number_of_one_bits.py)
