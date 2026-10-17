# TBC padding

Benchmark the pinned TBC padding class's add, remove, and padding-count operations using one bounded byte-output interface.

## Contract

- The `i64_array_bytes_output` ABI packs `[operation, offset, length, bytes...]`, with `0 <= length <= 256`, exactly `3 + length` signed 64-bit values, and bytes in `0..255`.
- Operation `0` calls AddPadding on the supplied full buffer. `length` is the buffer capacity and `offset` is where padding begins. The source fills `[offset, length)` with `0xFF` if the preceding byte's least significant bit is 0, or `0x00` if it is 1. For offset 0, the source uses the current final buffer byte to select the fill value, so length must be nonzero. Output is an 8-byte little-endian signed padding count (`length - offset`) followed by the full mutated buffer; the return value is bytes written (`8 + length`). No block-size argument exists in the pinned API: its caller supplies an already-sized buffer and offset.
- Operation `1` calls RemovePadding and requires `offset == 0`. Empty input returns empty output. Otherwise the final byte's least significant bit selects the candidate padding byte (`0x00` for even, `0xFF` for odd); the source removes the maximal matching suffix and leaves all other bytes unchanged. The return value is the output byte length.
- Operation `2` calls GetPaddingCount and requires `offset == 0` and nonempty input. The final byte must be `0x00` or `0xFF`; the source counts its trailing run. Output is the count as one little-endian signed 64-bit integer, and the return value is 8.
- Invalid input returns `-1`. A null output or insufficient capacity returns `-2` without writes. Maximum input is 259 i64 values and maximum output is 264 bytes.

## Source semantics

This package follows [`TbcPadding.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Crypto/Paddings/TbcPadding.cs) at commit `96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c`. TBC chooses a repeated `0x00` or `0xFF` byte from the last data bit. AddPadding fills the remainder of a caller-sized array; it does not calculate a block size. RemovePadding follows the source's suffix heuristic without validating the padded input.

See the [workload](workload.json) and [oracle](../../tbc_padding_oracle.py).

## Implementations

| Language | Port |
|---|---|
| C | [tbc_padding.c](../../../c/t/tbc_padding.c) |
| C3 | [tbc_padding.c3](../../../c3/t/tbc_padding.c3) |
| C++ | [tbc_padding.cpp](../../../cpp/t/tbc_padding.cpp) |
| Elisa | [tbc_padding.elisa](../../../elisa/t/tbc_padding.elisa) |
| Nim | [tbc_padding.nim](../../../nim/t/tbc_padding.nim) |
| Odin | [tbc_padding.odin](../../../odin/t/tbc_padding.odin) |
| Rust | [tbc_padding.rs](../../../rust/t/tbc_padding.rs) |
| V | [tbc_padding.v](../../../v/t/tbc_padding.v) |
| Zig | [tbc_padding.zig](../../../zig/t/tbc_padding.zig) |
