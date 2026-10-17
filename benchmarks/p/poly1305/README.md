# Poly1305

Compute the 16-byte Poly1305 authentication tag for a message and a 32-byte one-time key. This ports [TheAlgorithms Rust `poly1305.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/big_integer/poly1305.rs), which follows RFC 8439: clamp `r`, process each 16-byte chunk with its appended one bit, update the accumulator modulo `2^130 - 5`, add `s`, and return the low 128 bits in little-endian order. Each call starts with a fresh authenticator.

The `i64_array_bytes_output` ABI packs input as `[message_length, 32 key bytes, message bytes...]`. The message length is `0..64`; each key and message byte is represented as a signed-i64 slot in `0..255`. Valid frames contain exactly `33 + message_length` values.

## Bounds and invalid inputs

- A valid input has at most 97 slots. The parser accepts at most 98 slots so a single trailing value is rejected safely.
- Invalid frames or out-of-range byte values return `-1`. A null output or capacity below 16 returns `-2` without writing output.
- The source uses arbitrary-precision `BigUint` arithmetic and explicitly warns that those operations are not constant-time. This benchmark makes no constant-time guarantee.

The workload uses the `i64_array_bytes_output` ABI and `i64_array_bytes_output_call` comparison model.
