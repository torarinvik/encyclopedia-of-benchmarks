# Unsigned 53-bit Bitwise NOT

Complements an integer across all 53 bits of the unsigned safe-integer domain. For valid input `n`, the result is `(2^53 - 1) - n`; zero therefore maps to `2^53 - 1`, and `2^53 - 1` maps to zero. This fixed-width operation is distinct from `bitwise_complement`, which ignores leading zero bits.

## Contract

- Input is one signed 64-bit integer from `0` through `9,007,199,254,740,991` (`2^53 - 1`). Return `-1` for inputs outside this range.
- Return the 53-bit complement, `9,007,199,254,740,991 - n`, for valid input.
- The pinned Lua source precomputes complements for each byte, processes low bytes, handles the remaining low bits, and fills all leading positions with ones. A byte lookup is equivalent to subtracting that byte from 255; the ports keep the same byte and residual-bit structure using exact integer arithmetic.
- The domain is bounded to 53 bits, so the operation takes O(1) time and O(1) auxiliary space.

## Source

- [TheAlgorithms/Lua `src/bit/uint53/not.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/bit/uint53/not.lua)

## Workload and build

`workload.json` covers zero, low byte boundaries, the top input bit, values next to the maximum, the maximum, and invalid signed/domain boundaries. Build with `python3 benchmarks/build_scalar.py --algorithm uint53_bitwise_not --language LANGUAGE`.

## Ports

| Language | Source |
| --- | --- |
| C | [`c/u/uint53_bitwise_not.c`](../../../c/u/uint53_bitwise_not.c) |
| C3 | [`c3/u/uint53_bitwise_not.c3`](../../../c3/u/uint53_bitwise_not.c3) |
| C++ | [`cpp/u/uint53_bitwise_not.cpp`](../../../cpp/u/uint53_bitwise_not.cpp) |
| Elisa | [`elisa/u/uint53_bitwise_not.elisa`](../../../elisa/u/uint53_bitwise_not.elisa) |
| Nim | [`nim/u/uint53_bitwise_not.nim`](../../../nim/u/uint53_bitwise_not.nim) |
| Odin | [`odin/u/uint53_bitwise_not.odin`](../../../odin/u/uint53_bitwise_not.odin) |
| Rust | [`rust/u/uint53_bitwise_not.rs`](../../../rust/u/uint53_bitwise_not.rs) |
| V | [`v/u/uint53_bitwise_not.v`](../../../v/u/uint53_bitwise_not.v) |
| Zig | [`zig/u/uint53_bitwise_not.zig`](../../../zig/u/uint53_bitwise_not.zig) |
