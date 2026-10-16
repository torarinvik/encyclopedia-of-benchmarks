# Select Bits

This benchmark ports the pinned Lua function that extracts a one-indexed slice
of bits from an unsigned 53-bit integer.

## Contract

The i64_array_scalar input has one of these forms:

- [n]: use the source defaults from = 1 and to = 53.
- [n, from]: use the supplied first bit and the default to = 53.
- [n, from, to]: use both supplied bit positions.

n must be in [0, 2^53 - 1]. Each supplied bit position must be in [1, 53].
Bit positions are one-indexed, with bit 1 the least significant bit. The result
is floor((n mod 2^to) / 2^(from-1)). When from > to, the result is zero, as
in the source. Invalid input lengths, values, or bit positions return -1.

The scalar result is between 0 and 2^53 - 1.

## Workload

workload.json covers all three call forms, zero, the largest uint53 value, low
and high slices, reversed bounds, and malformed inputs.

## Pinned source

[TheAlgorithms/Lua select_bits.lua](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/bit/uint53/select_bits.lua)

## Implementations

| Language | Port |
|---|---|
| C | [c/s/select_bits.c](../../../c/s/select_bits.c) |
| C3 | [c3/s/select_bits.c3](../../../c3/s/select_bits.c3) |
| C++ | [cpp/s/select_bits.cpp](../../../cpp/s/select_bits.cpp) |
| Elisa | [elisa/s/select_bits.elisa](../../../elisa/s/select_bits.elisa) |
| Nim | [nim/s/select_bits.nim](../../../nim/s/select_bits.nim) |
| Odin | [odin/s/select_bits.odin](../../../odin/s/select_bits.odin) |
| Rust | [rust/s/select_bits.rs](../../../rust/s/select_bits.rs) |
| V | [v/s/select_bits.v](../../../v/s/select_bits.v) |
| Zig | [zig/s/select_bits.zig](../../../zig/s/select_bits.zig) |
