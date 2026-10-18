# SHA-2

This package preserves the six digest functions exposed by the pinned Rust
source: SHA-224, SHA-256, SHA-384, SHA-512, SHA-512/224, and SHA-512/256.
The two SHA-512/t variants use their own initial states; they are not truncated
SHA-512 digests.

## Contract

Input is a signed-i64 array `[variant, message_length, message_bytes...]`.
Variants `0..5` select SHA-224, SHA-256, SHA-384, SHA-512, SHA-512/224, and
SHA-512/256. Each message byte is an integer from 0 through 255, and the input
must contain exactly `2 + message_length` words. The maximum message is 4,096
bytes; the maximum valid input is 4,098 words, and 4,099 words are parseable to
reject trailing data.

Output is the raw digest bytes in big-endian order, with no header or text
encoding. Digest lengths by variant are 28, 32, 48, 64, 28, and 32 bytes, so
the maximum output is 64 bytes. Output capacity is measured in bytes.
Malformed input or a null input returns `-1`. A valid input with a null or
short output buffer returns `-2` without writes. Success returns the digest
byte count.

SHA-224 and SHA-256 use 64-byte blocks, a 64-bit big-endian message bit length,
and their respective 32-bit initial states. SHA-384, SHA-512, SHA-512/224,
and SHA-512/256 use 128-byte blocks, a 128-bit big-endian message bit length,
and their respective 64-bit initial states. SHA-512/224 and SHA-512/256 emit
the first 28 or 32 bytes of the state stream after compression with the
variant-specific IV.

## Pinned source

- Rust [`sha2.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/hashing/sha2.rs), `sha224`, `sha256`, `sha384`, `sha512`, `sha512_224`, and `sha512_256`, commit `fed66cb0c74c4a939ec5163648458a8c2b46fd4c`.

## Workload and oracle

- Workload: [`workload.json`](workload.json)
- Oracle: [`benchmarks/sha2_oracle.py`](../../sha2_oracle.py), using Python's standard hashlib functions and a SHA-512/t fallback with the pinned IVs.

## Language ports

| Language | Port |
|---|---|
| C | [`c/s/sha2.c`](../../../c/s/sha2.c) |
| C3 | [`c3/s/sha2.c3`](../../../c3/s/sha2.c3) |
| C++ | [`cpp/s/sha2.cpp`](../../../cpp/s/sha2.cpp) |
| Elisa | [`elisa/s/sha2.elisa`](../../../elisa/s/sha2.elisa) |
| Nim | [`nim/s/sha2.nim`](../../../nim/s/sha2.nim) |
| Odin | [`odin/s/sha2.odin`](../../../odin/s/sha2.odin) |
| Rust | [`rust/s/sha2.rs`](../../../rust/s/sha2.rs) |
| V | [`v/s/sha2.v`](../../../v/s/sha2.v) |
| Zig | [`zig/s/sha2.zig`](../../../zig/s/sha2.zig) |
