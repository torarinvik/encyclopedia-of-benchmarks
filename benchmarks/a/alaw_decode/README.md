# A-law PCM decoding

This benchmark decodes one 8-bit A-law codeword into a signed linear PCM sample, following the pinned C `decode` operation. It reverses the alternating-bit mask, extracts the sign, segment, and quantization nibble, restores the midpoint of the quantization step, and expands according to the segment.

## Contract

- Input is one integer in `[0, 255]` representing an A-law octet.
- Return the decoded signed PCM sample as an integer. Results are multiples of eight in the signed 16-bit range.
- Values outside the octet range return `-1`.

The source's `decode` routine is separate from its `encode` routine, which is benchmarked by [`alaw`](../alaw/README.md). The pinned sample pairs include codewords `250, 122, 230, 156, 97, 213, 170, 42`, decoded as `1008, -1008, 1248, 3264, -1312, 8, 32256, -32256`.

## Workload

[`workload.json`](workload.json) covers the pinned sample table, input octet boundaries, segment transitions, and invalid values.

## Source

- [Pinned C `audio/alaw.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/audio/alaw.c) contains the reference `decode` routine.

## Implementations

| Language | Source |
|---|---|
| C | [`c/a/alaw_decode.c`](../../../c/a/alaw_decode.c) |
| C3 | [`c3/a/alaw_decode.c3`](../../../c3/a/alaw_decode.c3) |
| C++ | [`cpp/a/alaw_decode.cpp`](../../../cpp/a/alaw_decode.cpp) |
| Elisa | [`elisa/a/alaw_decode.elisa`](../../../elisa/a/alaw_decode.elisa) |
| Nim | [`nim/a/alaw_decode.nim`](../../../nim/a/alaw_decode.nim) |
| Odin | [`odin/a/alaw_decode.odin`](../../../odin/a/alaw_decode.odin) |
| Rust | [`rust/a/alaw_decode.rs`](../../../rust/a/alaw_decode.rs) |
| V | [`v/a/alaw_decode.v`](../../../v/a/alaw_decode.v) |
| Zig | [`zig/a/alaw_decode.zig`](../../../zig/a/alaw_decode.zig) |
