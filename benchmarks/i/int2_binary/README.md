# Integer to fixed-width binary

## Contract

Encode an unsigned 32-bit integer as exactly 32 ASCII `0`/`1` bytes, most-significant bit first. The supported input range is 0 through 4,294,967,295; other values return `-1`. If the output buffer is missing or smaller than 32 bytes, return `-2`. The exported C ABI entry point is `int64_t int2_binary(int64_t value, uint8_t *output, size_t output_capacity);`.

## Source review

The pinned C# file has `ushort`, `uint`, and `ulong` overloads. This benchmark represents the `uint` overload: it begins at bit 31 and appends one character for each bit down to zero. The code uses a remaining-value comparison and subtraction at each position, preserving the source's fixed-width output, including leading zeros. The two wider overloads use the same algorithm at 16 and 64 bits; they are not selected by this `uint` workload contract.

## Workload

[`workload.json`](workload.json) covers zero, small values with leading zeros, byte and word boundaries, the highest bit, the maximum `uint`, and invalid signed/range inputs.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/i/int2_binary.c`](../../../c/i/int2_binary.c) |
| C3 | [`c3/i/int2_binary.c3`](../../../c3/i/int2_binary.c3) |
| C++ | [`cpp/i/int2_binary.cpp`](../../../cpp/i/int2_binary.cpp) |
| Elisa | [`elisa/i/int2_binary.elisa`](../../../elisa/i/int2_binary.elisa) |
| Nim | [`nim/i/int2_binary.nim`](../../../nim/i/int2_binary.nim) |
| Odin | [`odin/i/int2_binary.odin`](../../../odin/i/int2_binary.odin) |
| Rust | [`rust/i/int2_binary.rs`](../../../rust/i/int2_binary.rs) |
| V | [`v/i/int2_binary.v`](../../../v/i/int2_binary.v) |
| Zig | [`zig/i/int2_binary.zig`](../../../zig/i/int2_binary.zig) |

## TheAlgorithms reference

- [C# `Int2Binary.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Other/Int2Binary.cs)
