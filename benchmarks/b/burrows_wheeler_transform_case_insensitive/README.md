# ASCII case-insensitive Burrows-Wheeler transform

This benchmark sorts cyclic rotations by ASCII case-folded byte order and emits the original bytes from the sorted rows. It preserves letter case in the transformed column. This is the behavior of TheAlgorithms Rust `src/string/burrows_wheeler_transform.rs` and differs from the case-sensitive compression-module transform on mixed-case inputs.

## Contract

- Input is `[length, byte_0, ..., byte_(length-1)]`; `length` is 0 through 256 and each byte is 0 through 127.
- Only `A` through `Z` are folded to lowercase for rotation comparison. All other bytes retain their value. Equal folded rotations are ordered by starting offset.
- The primary index is the last row whose original bytes equal the input, matching the source module's index assignment when periodic input has identical rotations. Empty input returns index 0 and an empty transformed column.
- Output is a four-byte unsigned little-endian primary index followed by the transformed bytes. Invalid input returns `-1`; insufficient output capacity returns `-2`.

[`workload.json`](workload.json) includes the source examples, mixed-case sort differences, folded-key ties, periodic inputs, empty input, ASCII boundaries, and malformed values. The nine ports use the shared `i64_array_bytes_output` ABI family and `benchmarks/run_i64_array_bytes_output.py` recorder.

## Reviewed source

- [Rust string `burrows_wheeler_transform.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/string/burrows_wheeler_transform.rs)
