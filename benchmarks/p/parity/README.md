# Set-Bit Parity

This package benchmarks the pinned [TheAlgorithms/Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/bit_manipulation/parity.py). It returns 1 when the input has an odd number of set bits and 0 when it has an even number, clearing one set bit per iteration.

The scalar ABI accepts one signed 64-bit integer. Valid inputs are 0 through `INT64_MAX`; negative values are invalid and return -1. The output is the integer parity bit. Runtime is O(popcount(n)) and auxiliary space is O(1).

This differs from `hamming_weight`, which returns the number of set bits, and from `parity_check`, which returns a boolean for even parity.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/parity.c`](../../../c/p/parity.c) |
| C3 | [`c3/p/parity.c3`](../../../c3/p/parity.c3) |
| C++ | [`cpp/p/parity.cpp`](../../../cpp/p/parity.cpp) |
| Elisa | [`elisa/p/parity.elisa`](../../../elisa/p/parity.elisa) |
| Nim | [`nim/p/parity.nim`](../../../nim/p/parity.nim) |
| Odin | [`odin/p/parity.odin`](../../../odin/p/parity.odin) |
| Rust | [`rust/p/parity.rs`](../../../rust/p/parity.rs) |
| V | [`v/p/parity.v`](../../../v/p/parity.v) |
| Zig | [`zig/p/parity.zig`](../../../zig/p/parity.zig) |
