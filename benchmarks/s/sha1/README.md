# SHA-1

This package computes the standard SHA-1 digest of a byte sequence.

## Contract

The `i64_array_bytes_output` ABI accepts 0 to 4,096 signed 64-bit input slots, each containing a byte in `0..255`. The function appends the SHA-1 `0x80` bit, zero padding, and the original bit length as an unsigned 64-bit big-endian value. It processes 512-bit blocks with the standard 80-round schedule and emits the five final state words as 20 bytes in big-endian word order.

Success returns 20 and writes exactly 20 digest bytes. Invalid length, a null input pointer for a nonempty message, or a value outside `0..255` returns `-1`. A null or undersized output buffer returns `-2` without writing. Empty input is valid. The input is not modified.

## Source notes

The shared raw-byte contract follows the pinned C++, Go, JavaScript, Python, and Rust implementations. JavaScript must map each input byte to one code unit in U+0000 through U+00FF; converting the bytes through UTF-8 would change the digest. Python and the C++ adapter expose hexadecimal text and are normalized to the same raw digest bytes. The two C++ source copies are mirrors.

The pinned AArch64 assembly file is a fixed-input Rosetta Code demo with a 1,000-byte scratch buffer and an external I/O include. It is architecture-specific and does not define this arbitrary-byte contract.

## Pinned sources

- C++ [`hashing/sha1.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/hashing/sha1.cpp)
- C++ mirror [`hashing/sha1.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/hashing/sha1.cpp)
- Go [`hashing/sha1/sha1.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/hashing/sha1/sha1.go)
- JavaScript [`Hashes/SHA1.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Hashes/SHA1.js)
- Python [`hashes/sha1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/hashes/sha1.py)
- Rust [`src/hashing/sha1.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/hashing/sha1.rs)
- AArch64 assembly [`misc/sha1.s`](https://github.com/TheAlgorithms/AArch64_Assembly/blob/cb138a856a3af14d3d3dfcd2743d43841eec566f/misc/sha1.s)

## Build and run

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm sha1 --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/s/sha1/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/s/sha1.c`](../../../c/s/sha1.c) |
| C3 | [`c3/s/sha1.c3`](../../../c3/s/sha1.c3) |
| C++ | [`cpp/s/sha1.cpp`](../../../cpp/s/sha1.cpp) |
| Elisa | [`elisa/s/sha1.elisa`](../../../elisa/s/sha1.elisa) |
| Nim | [`nim/s/sha1.nim`](../../../nim/s/sha1.nim) |
| Odin | [`odin/s/sha1.odin`](../../../odin/s/sha1.odin) |
| Rust | [`rust/s/sha1.rs`](../../../rust/s/sha1.rs) |
| V | [`v/s/sha1.v`](../../../v/s/sha1.v) |
| Zig | [`zig/s/sha1.zig`](../../../zig/s/sha1.zig) |
