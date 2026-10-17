# UTF-8 length

## Contract

This benchmark extracts the byte-length and character-count loops from the pinned AArch64 example. Input is a packed signed-i64 array [payload_byte_length, payload_bytes..., 0], where the final zero is the only NUL terminator. The payload length is 0..256; payload values must be bytes with no embedded NUL.

The bounded domain accepts well-formed UTF-8 scalar sequences encoded with one, two, or three bytes. Four-byte scalars are excluded because the source loop advances by three bytes for a leading byte matching its three-byte mask. The wrapper rejects malformed, overlong, surrogate, truncated, or four-byte sequences before running the byte and character count.

A valid call writes two little-endian signed-i64 values, [payload_byte_length, Unicode_scalar_count], and returns 16. Invalid framing, input values, or UTF-8 return -1. A null input pointer returns -1. A null output pointer or output capacity below 16 returns -2, with no output written. Input lengths must be exactly payload_byte_length + 2; maximum valid and parseable lengths are 258 and 259 values.

## Workload

[workload.json](workload.json) covers empty and ASCII payloads, the source's møøse€ sample, one/two/three-byte sequences, maximum payloads, invalid UTF-8 and framing, null input/output, and insufficient capacity.

## TheAlgorithms reference

- AArch64 [string/length.s](https://github.com/TheAlgorithms/AArch64_Assembly/blob/cb138a856a3af14d3d3dfcd2743d43841eec566f/string/length.s) first scans to NUL for byte length, then counts characters by inspecting the leading-byte masks and advancing one, two, or three bytes.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/l/length.c](../../../c/l/length.c) |
| C3 | [c3/l/length.c3](../../../c3/l/length.c3) |
| C++ | [cpp/l/length.cpp](../../../cpp/l/length.cpp) |
| Elisa | [elisa/l/length.elisa](../../../elisa/l/length.elisa) |
| Nim | [nim/l/length.nim](../../../nim/l/length.nim) |
| Odin | [odin/l/length.odin](../../../odin/l/length.odin) |
| Rust | [rust/l/length.rs](../../../rust/l/length.rs) |
| V | [v/l/length.v](../../../v/l/length.v) |
| Zig | [zig/l/length.zig](../../../zig/l/length.zig) |
