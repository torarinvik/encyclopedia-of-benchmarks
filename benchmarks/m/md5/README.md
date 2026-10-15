# MD5

This package computes an MD5 digest over a byte array and returns the 16 digest bytes in their standard order.

## Contract

The `i64_array_bytes_output` ABI accepts 0 to 4,096 signed 64-bit input slots, each in the byte range `0..255`. It appends the MD5 `0x80` bit, zero padding to byte offset 56 in the final 64-byte block, and the original bit length as an unsigned 64-bit little-endian value. It processes each block with the four standard MD5 rounds and emits the final four state words low byte first.

Success returns 16 and writes exactly 16 raw digest bytes. Invalid length, null input for a nonempty message, or a value outside `0..255` returns `-1`. A null or undersized output buffer returns `-2`; errors leave the output untouched. The input is not modified. Runtime is O(n) and auxiliary space is O(1).

## Sources

The package follows the standard MD5 byte and padding semantics in the pinned implementations:

- C++ [`hashing/md5.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/hashing/md5.cpp)
- Python [`hashes/md5.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/hashes/md5.py)
- Go [`hashing/md5/md5.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/hashing/md5/md5.go)
- JavaScript [`Hashes/MD5.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Hashes/MD5.js)
- Rust [`src/hashing/md5.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/hashing/md5.rs)

The pinned C++ implementation is correct on little-endian hosts; its endian condition skips the required conversion on big-endian hosts. These ports construct the specified little-endian words and length bytes directly, so their result follows standard MD5 independent of host byte order.

## Workload

[`workload.json`](workload.json) includes the standard empty, `a`, `abc`, quick-brown-fox, and alphanumeric vectors; messages at padding boundaries; embedded zero and high bytes; all byte values; the maximum supported length; invalid bytes; and insufficient output capacity.

## Build and run

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm md5 --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/m/md5/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/m/md5.c`](../../../c/m/md5.c) |
| C3 | [`c3/m/md5.c3`](../../../c3/m/md5.c3) |
| C++ | [`cpp/m/md5.cpp`](../../../cpp/m/md5.cpp) |
| Elisa | [`elisa/m/md5.elisa`](../../../elisa/m/md5.elisa) |
| Nim | [`nim/m/md5.nim`](../../../nim/m/md5.nim) |
| Odin | [`odin/m/md5.odin`](../../../odin/m/md5.odin) |
| Rust | [`rust/m/md5.rs`](../../../rust/m/md5.rs) |
| V | [`v/m/md5.v`](../../../v/m/md5.v) |
| Zig | [`zig/m/md5.zig`](../../../zig/m/md5.zig) |
