# Unsigned 53-bit Population Count

Counts the set bits in an unsigned safe-integer value. The result ranges from zero to 53 and counts bits in the complete binary representation; leading zeroes do not contribute.

## Contract

- Input is one signed 64-bit integer from `0` through `9,007,199,254,740,991` (`2^53 - 1`). Return `-1` for inputs outside this range.
- Return the number of one bits in the input, from zero through 53.
- The pinned Lua source precomputes the population count for each byte, then sums one table lookup per byte. The ports preserve the byte decomposition and compute each byte's count with the source's bit-extraction loop instead of storing a separate 256-entry table.
- The input has at most 53 bits, so time and auxiliary space are O(1) for this bounded contract.

## Source

- [TheAlgorithms/Lua `src/bit/uint53/ones_count.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/bit/uint53/ones_count.lua)

## Relationship to Hamming weight

This operation is the same mathematical population count, but the existing `hamming_weight` benchmark is explicitly bounded to unsigned 32-bit inputs. This package preserves the Lua source's wider unsigned 53-bit domain, including values above `2^32 - 1`.

## Workload and build

`workload.json` covers zero, byte boundaries, low and high bits, dense bit patterns, the maximum safe integer, and invalid signed/domain boundaries. Build with `python3 benchmarks/build_scalar.py --algorithm uint53_ones_count --language LANGUAGE`.

## Ports

| Language | Source |
| --- | --- |
| C | [`c/u/uint53_ones_count.c`](../../../c/u/uint53_ones_count.c) |
| C3 | [`c3/u/uint53_ones_count.c3`](../../../c3/u/uint53_ones_count.c3) |
| C++ | [`cpp/u/uint53_ones_count.cpp`](../../../cpp/u/uint53_ones_count.cpp) |
| Elisa | [`elisa/u/uint53_ones_count.elisa`](../../../elisa/u/uint53_ones_count.elisa) |
| Nim | [`nim/u/uint53_ones_count.nim`](../../../nim/u/uint53_ones_count.nim) |
| Odin | [`odin/u/uint53_ones_count.odin`](../../../odin/u/uint53_ones_count.odin) |
| Rust | [`rust/u/uint53_ones_count.rs`](../../../rust/u/uint53_ones_count.rs) |
| V | [`v/u/uint53_ones_count.v`](../../../v/u/uint53_ones_count.v) |
| Zig | [`zig/u/uint53_ones_count.zig`](../../../zig/u/uint53_ones_count.zig) |
