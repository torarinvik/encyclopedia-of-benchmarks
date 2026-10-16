# Burrows-Wheeler transform

This benchmark applies the case-sensitive Burrows-Wheeler transform to one non-empty ASCII byte string. It sorts every cyclic rotation lexicographically, then returns the last column and the row containing the original rotation.

## Contract

- Input is `[length, byte_0, ..., byte_(length-1)]`; `length` is 1 through 256 and each byte is 0 through 127.
- Equal rotations are ordered by their starting offset, so periodic inputs have a deterministic primary index.
- Output is a four-byte unsigned little-endian primary index followed by the transformed bytes. Invalid input returns `-1`; insufficient output capacity returns `-2`.
- The source family's compression and Python implementations use case-sensitive ordering. Rust's separate `src/string/burrows_wheeler_transform.rs` sorts rotation keys case-insensitively and therefore represents a distinct contract for mixed-case inputs.

[`workload.json`](workload.json) covers the pinned source examples, repeated and periodic strings, mixed case, ASCII boundary bytes, and malformed lengths and byte values. The nine ports use the shared `i64_array_bytes_output` ABI family and `benchmarks/run_i64_array_bytes_output.py` recorder.

## Reviewed sources

- [R `burrows.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/string_manipulation/burrows.r) appends `$` and sorts cyclic rotations; the alias normalizes to ordinal byte order because R's default character sort is locale-sensitive. Its returned original string and full rotation matrix are outside this contract.
- [Python `burrows_wheeler.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_compression/burrows_wheeler.py)
- [Rust compression `burrows_wheeler_transform.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/compression/burrows_wheeler_transform.rs)
- [C# `BurrowsWheelerTransform.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/DataCompression/BurrowsWheelerTransform.cs)
- [Java `BurrowsWheelerTransform.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/compression/BurrowsWheelerTransform.java)
