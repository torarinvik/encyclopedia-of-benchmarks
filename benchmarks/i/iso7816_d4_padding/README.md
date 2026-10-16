# ISO 7816-4 padding

This benchmark ports the three operations in the pinned C# `Iso7816D4Padding` class: add the `0x80` marker and zero fill, remove a valid padding suffix, and count its bytes. The implementations use ordinary integer and array operations and do not rely on architecture-specific instructions.

## Contract

Input is `[mode, block_size_or_zero, byte_count, bytes...]`, with at most 24 data bytes.

- Mode 0 adds ISO 7816-4 padding for a block size from 1 through 8. The output length is the next block boundary, including a full block when the data is already aligned. The function returns the number of bytes added.
- Mode 1 validates a suffix of `0x80` followed by zero or more zeros and returns the marker index, which is the payload length.
- Mode 2 validates the same suffix and returns its byte count. Its bounded scan visits the full input buffer.
- Modes 1 and 2 require `block_size_or_zero` to be zero. All data bytes must be in 0..255. Invalid input returns -1.

The 24-byte input limit and 8-byte maximum block size keep padded output within the 32-byte temporary buffer. Mode 1 follows `RemovePadding`; mode 2 follows `GetPaddingCount` from the pinned source. The count implementation preserves the source method’s full-buffer scan without making a constant-time guarantee.

See [workload](workload.json), [oracle](../../iso7816_d4_padding_oracle.py), and pinned [C# source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Crypto/Paddings/Iso7816D4Padding.cs). The scalar-array verifier is `python3 benchmarks/verify_i64_array_scalar.py --algorithms iso7816_d4_padding`.

| Language | Port |
|---|---|
| C | [c/i/iso7816_d4_padding.c](../../../c/i/iso7816_d4_padding.c) |
| C3 | [c3/i/iso7816_d4_padding.c3](../../../c3/i/iso7816_d4_padding.c3) |
| C++ | [cpp/i/iso7816_d4_padding.cpp](../../../cpp/i/iso7816_d4_padding.cpp) |
| Elisa | [elisa/i/iso7816_d4_padding.elisa](../../../elisa/i/iso7816_d4_padding.elisa) |
| Nim | [nim/i/iso7816_d4_padding.nim](../../../nim/i/iso7816_d4_padding.nim) |
| Odin | [odin/i/iso7816_d4_padding.odin](../../../odin/i/iso7816_d4_padding.odin) |
| Rust | [rust/i/iso7816_d4_padding.rs](../../../rust/i/iso7816_d4_padding.rs) |
| V | [v/i/iso7816_d4_padding.v](../../../v/i/iso7816_d4_padding.v) |
| Zig | [zig/i/iso7816_d4_padding.zig](../../../zig/i/iso7816_d4_padding.zig) |
