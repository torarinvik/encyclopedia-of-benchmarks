# BLAKE2b-512

This benchmark computes the unkeyed BLAKE2b digest with a fixed 64-byte output.

## Contract

The `i64_array_bytes_output` ABI accepts 0 to 4,096 signed 64-bit slots, each holding one byte in `0..255`. It processes 128-byte blocks with the BLAKE2b parameter block for an unkeyed 64-byte digest, uses the standard twelve-round compression, marks only the last block as final, and serializes the eight result words in little-endian order.

Success returns 64 and writes exactly 64 bytes. Invalid length, a null input pointer for a nonempty message, or a value outside `0..255` returns `-1`. A null or undersized output buffer returns `-2` without writing. Empty input is valid.

## Source notes

The pinned Rust implementation exposes keyed hashing and configurable digest lengths. This shared contract selects its unkeyed BLAKE2b-512 configuration so all nine language ports compare the same operation. The implementations use portable 64-bit integer operations and byte-wise little-endian loads; they do not require architecture-specific instructions.

The workload covers empty and short messages, embedded zero and high bytes, the pinned examples, lengths around the 128-byte block boundary, the 4,096-byte limit, malformed bytes, an overlength message, and a 63-byte output buffer. The verifier compares output bytes against Python's `hashlib.blake2b` and checks that undersized buffers remain untouched.

## Pinned source

- Rust [`hashing/blake2b.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/hashing/blake2b.rs)
- C [`hash/hash_blake2b.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/hash/hash_blake2b.c), mapped as an alias for the same unkeyed 64-byte configuration

## Build and run

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm blake2b --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/b/blake2b/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm blake2b --languages rust
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/b/blake2b.c`](../../../c/b/blake2b.c) |
| C3 | [`c3/b/blake2b.c3`](../../../c3/b/blake2b.c3) |
| C++ | [`cpp/b/blake2b.cpp`](../../../cpp/b/blake2b.cpp) |
| Elisa | [`elisa/b/blake2b.elisa`](../../../elisa/b/blake2b.elisa) |
| Nim | [`nim/b/blake2b.nim`](../../../nim/b/blake2b.nim) |
| Odin | [`odin/b/blake2b.odin`](../../../odin/b/blake2b.odin) |
| Rust | [`rust/b/blake2b.rs`](../../../rust/b/blake2b.rs) |
| V | [`v/b/blake2b.v`](../../../v/b/blake2b.v) |
| Zig | [`zig/b/blake2b.zig`](../../../zig/b/blake2b.zig) |
