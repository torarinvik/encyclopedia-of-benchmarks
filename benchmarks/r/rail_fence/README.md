# Rail Fence cipher

This package ports the pinned Rust Rail Fence encrypt and decrypt functions. The contract is limited to ASCII bytes so Rust's `str::chars()` traversal and the decrypt function's byte-length-based index stream agree exactly.

## Contract

- The `i64_array_bytes_output` input is `[mode, rails, byte_length, ascii_bytes...]`. Mode `0` encrypts and mode `1` decrypts. The packed array length must equal `3 + byte_length`.
- `rails` is 2 through 8; `byte_length` is 0 through 256; each text byte is 0 through 127. Empty text is valid.
- Output is the exact transformed byte string with no terminator. The return value is the output byte count. Malformed input returns `-1`; a null output pointer or a capacity smaller than the result returns `-2`.
- The source's rail sequence is the repeating zigzag `0, 1, ..., rails-1, ..., 1`. Rails 0 and 1 are excluded because the pinned iterator is undefined or empty there. Non-ASCII input is excluded because the source mixes UTF-8 byte length and character iteration.

The [workload](workload.json) covers both directions, the pinned Rust examples, empty and short text, rails greater than the text length, embedded NUL, the maximum text length, malformed packed input, and insufficient capacity. The independent oracle is [`benchmarks/rail_fence_oracle.py`](../../rail_fence_oracle.py).

## Pinned source

- [TheAlgorithms/Rust `rail_fence.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/ciphers/rail_fence.rs)

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm rail_fence --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm rail_fence
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm rail_fence --languages rust
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/r/rail_fence.c`](../../../c/r/rail_fence.c) |
| C3 | [`c3/r/rail_fence.c3`](../../../c3/r/rail_fence.c3) |
| C++ | [`cpp/r/rail_fence.cpp`](../../../cpp/r/rail_fence.cpp) |
| Elisa | [`elisa/r/rail_fence.elisa`](../../../elisa/r/rail_fence.elisa) |
| Nim | [`nim/r/rail_fence.nim`](../../../nim/r/rail_fence.nim) |
| Odin | [`odin/r/rail_fence.odin`](../../../odin/r/rail_fence.odin) |
| Rust | [`rust/r/rail_fence.rs`](../../../rust/r/rail_fence.rs) |
| V | [`v/r/rail_fence.v`](../../../v/r/rail_fence.v) |
| Zig | [`zig/r/rail_fence.zig`](../../../zig/r/rail_fence.zig) |
