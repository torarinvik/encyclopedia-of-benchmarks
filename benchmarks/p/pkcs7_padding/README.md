# PKCS#7 padding

## Contract

This benchmark extracts `AddPadding`, `RemovePadding`, and `GetPaddingCount` from the pinned C# `Pkcs7Padding`. Input is `[operation, block_size, input_offset, data_length, bytes...]`, where operation 0 adds padding, 1 removes padding, and 2 returns the padding count. Block sizes are 1..16, buffers are 1..64 bytes, and byte values are 0..255. `input_offset` must be in `0..data_length` for operation 0, which uses it as the write position. Operations 1 and 2 ignore the offset value.

Operation 0 returns bytes `[padding_count, mutated_input...]`. It preserves the source quirk that computes the count from the full input array length, not from `input_offset`; the count is a full block when the input length is already aligned. It writes the repeated count at `input_offset` and is invalid when the write would exceed the buffer.

Operation 1 requires a nonempty input whose length is a block-size multiple. The final byte must be from 1 through `block_size`, and all indicated suffix bytes must match; output is the unpadded prefix. Operation 2 returns the padding count as one byte after checking a nonempty matching suffix. It does not require a block-aligned input length and, as in the source, does not separately reject a count greater than `block_size` when the suffix is present. It scans the full bounded input and uses the source's masked bitwise suffix check without exiting early on a mismatch.

Malformed input or invalid padding returns `-1`. A null output pointer or insufficient output capacity returns `-2`, with no output bytes written on errors.

## Workload

[`workload.json`](workload.json) covers each operation, full-block padding, the length-versus-offset behavior, output bounds, malformed padding, non-block-aligned count queries, and the source's count validation behavior.

## TheAlgorithms reference

- C# [`Pkcs7Padding`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Crypto/Paddings/Pkcs7Padding.cs) implements padding, removal, and padding-count operations for block sizes 1..255.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/pkcs7_padding.c](../../../c/p/pkcs7_padding.c) |
| C3 | [c3/p/pkcs7_padding.c3](../../../c3/p/pkcs7_padding.c3) |
| C++ | [cpp/p/pkcs7_padding.cpp](../../../cpp/p/pkcs7_padding.cpp) |
| Elisa | [elisa/p/pkcs7_padding.elisa](../../../elisa/p/pkcs7_padding.elisa) |
| Nim | [nim/p/pkcs7_padding.nim](../../../nim/p/pkcs7_padding.nim) |
| Odin | [odin/p/pkcs7_padding.odin](../../../odin/p/pkcs7_padding.odin) |
| Rust | [rust/p/pkcs7_padding.rs](../../../rust/p/pkcs7_padding.rs) |
| V | [v/p/pkcs7_padding.v](../../../v/p/pkcs7_padding.v) |
| Zig | [zig/p/pkcs7_padding.zig](../../../zig/p/pkcs7_padding.zig) |
