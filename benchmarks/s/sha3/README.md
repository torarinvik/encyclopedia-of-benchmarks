# SHA-3

This package implements the four pinned Rust SHA-3 functions: SHA3-224,
SHA3-256, SHA3-384, and SHA3-512. These use the SHA-3 domain-separation
padding and are distinct from raw Keccak.

## Contract

Input is a signed-i64 array `[variant, message_length, message_bytes...]`.
Variants `0..3` select SHA3-224, SHA3-256, SHA3-384, and SHA3-512. Each message
byte is an integer from 0 through 255, and the input must contain exactly
`2 + message_length` words. The maximum message is 4,096 bytes; the maximum
valid input is 4,098 words, and 4,099 words are parseable to reject trailing
data.

Output is the raw digest bytes, with no length prefix or text encoding. Digest
lengths are 28, 32, 48, and 64 bytes for variants 0 through 3. Capacity is
measured in bytes. Malformed input, a null input, or an unsupported variant
returns `-1`. A valid input with a null or short output buffer returns `-2`
without writes. Success returns the number of digest bytes.

The pinned source converts each byte to bits least-significant bit first,
appends the SHA-3 domain-separation bits, applies `pad10*1`, and runs the
Keccak-f[1600] sponge with a rate selected by the digest size. The workload
includes all four rates' block boundaries as well as the maximum input size.

## Pinned source

- Rust [`sha3.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/hashing/sha3.rs), `sha3_224`, `sha3_256`, `sha3_384`, and `sha3_512`, commit `fed66cb0c74c4a939ec5163648458a8c2b46fd4c`.

## Workload and oracle

- Workload: [`workload.json`](workload.json)
- Oracle: [`benchmarks/sha3_oracle.py`](../../sha3_oracle.py), using Python's standard SHA-3 digest functions.

## Language ports

| Language | Port |
|---|---|
| C | [`c/s/sha3.c`](../../../c/s/sha3.c) |
| C3 | [`c3/s/sha3.c3`](../../../c3/s/sha3.c3) |
| C++ | [`cpp/s/sha3.cpp`](../../../cpp/s/sha3.cpp) |
| Elisa | [`elisa/s/sha3.elisa`](../../../elisa/s/sha3.elisa) |
| Nim | [`nim/s/sha3.nim`](../../../nim/s/sha3.nim) |
| Odin | [`odin/s/sha3.odin`](../../../odin/s/sha3.odin) |
| Rust | [`rust/s/sha3.rs`](../../../rust/s/sha3.rs) |
| V | [`v/s/sha3.v`](../../../v/s/sha3.v) |
| Zig | [`zig/s/sha3.zig`](../../../zig/s/sha3.zig) |
