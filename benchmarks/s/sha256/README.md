# SHA-256

This package computes the standard SHA-256 digest of a byte sequence.

## Contract

The `i64_array_bytes_output` ABI accepts 0 to 4,096 signed 64-bit input slots, each containing a byte in `0..255`. It appends the SHA-256 `0x80` bit, zero padding, and the original bit length as an unsigned 64-bit big-endian value. The 512-bit blocks use the standard 64-round schedule. Output is the eight final state words serialized as 32 big-endian bytes.

Success returns 32 and writes exactly 32 digest bytes. Invalid length, a null input pointer for a nonempty message, or a value outside `0..255` returns `-1`. A null or undersized output buffer returns `-2` without writing. Empty input is valid.

## Source notes

The pinned C++, Go, JavaScript, and Python implementations share standard SHA-256 over raw bytes. JavaScript maps each byte to a single code unit in U+0000 through U+00FF; converting through UTF-8 would change the digest. C++ and Python hexadecimal outputs normalize to raw digest bytes. The pinned AArch64 source is a fixed-input Raspberry Pi demo with an external include and 1,000-byte scratch area, so it does not define the generic byte-array contract.

## Pinned sources

- C++ [`hashing/sha256.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/hashing/sha256.cpp)
- Go [`hashing/sha256/sha256.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/hashing/sha256/sha256.go)
- JavaScript [`Hashes/SHA256.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Hashes/SHA256.js)
- Python [`hashes/sha256.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/hashes/sha256.py)
- AArch64 assembly [`misc/sha256.s`](https://github.com/TheAlgorithms/AArch64_Assembly/blob/cb138a856a3af14d3d3dfcd2743d43841eec566f/misc/sha256.s)

## Build and run

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm sha256 --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/s/sha256/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/s/sha256.c`](../../../c/s/sha256.c) |
| C3 | [`c3/s/sha256.c3`](../../../c3/s/sha256.c3) |
| C++ | [`cpp/s/sha256.cpp`](../../../cpp/s/sha256.cpp) |
| Elisa | [`elisa/s/sha256.elisa`](../../../elisa/s/sha256.elisa) |
| Nim | [`nim/s/sha256.nim`](../../../nim/s/sha256.nim) |
| Odin | [`odin/s/sha256.odin`](../../../odin/s/sha256.odin) |
| Rust | [`rust/s/sha256.rs`](../../../rust/s/sha256.rs) |
| V | [`v/s/sha256.v`](../../../v/s/sha256.v) |
| Zig | [`zig/s/sha256.zig`](../../../zig/s/sha256.zig) |
