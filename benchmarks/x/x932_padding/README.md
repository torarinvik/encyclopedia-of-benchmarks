# X9.23 padding (fixed zero filler)

Pad a byte sequence to a block boundary using the fixed-zero mode of the pinned C# X9.23 padding class. The final padding byte stores the number of added bytes.

## Contract

The `i64_array_bytes_output` ABI accepts `[block_size, payload_bytes...]`, where block size is 1–64 and payload has at most 256 bytes in `0..255`. The encoded result is the payload, zero bytes, and a final byte equal to the padding length. Padding always adds at least one byte, so an already aligned payload receives a full block. The benchmark fixes the source constructor's `useRandomPadding` option to false; its random mode is outside this deterministic contract. Invalid input returns `-1`, and insufficient output capacity returns `-2`. The algorithm takes O(n + b) time and O(1) auxiliary space beyond the output buffer.

[`workload.json`](workload.json) includes partial, exact, empty, and one-byte-block inputs plus capacity and invalid-input cases.

Pinned source: [TheAlgorithms/C-Sharp `X932Padding.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Crypto/Paddings/X932Padding.cs). The benchmark ports `AddPadding` with zero filler; it does not model the source's optional random mode or its removal helpers.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/x/x932_padding.c`](../../../c/x/x932_padding.c) |
| C3 | [`c3/x/x932_padding.c3`](../../../c3/x/x932_padding.c3) |
| C++ | [`cpp/x/x932_padding.cpp`](../../../cpp/x/x932_padding.cpp) |
| Elisa | [`elisa/x/x932_padding.elisa`](../../../elisa/x/x932_padding.elisa) |
| Nim | [`nim/x/x932_padding.nim`](../../../nim/x/x932_padding.nim) |
| Odin | [`odin/x/x932_padding.odin`](../../../odin/x/x932_padding.odin) |
| Rust | [`rust/x/x932_padding.rs`](../../../rust/x/x932_padding.rs) |
| V | [`v/x/x932_padding.v`](../../../v/x/x932_padding.v) |
| Zig | [`zig/x/x932_padding.zig`](../../../zig/x/x932_padding.zig) |
