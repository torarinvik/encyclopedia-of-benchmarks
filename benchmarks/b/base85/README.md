# Base85 codec

Encode arbitrary bytes as the unframed Ascii85 variant used by the Rust and Python source candidates, or decode that representation back into bytes. A mode-based array contract lets both operations use the shared byte-output ABI.

## Contract

- Input is `[mode, values...]`, with total length 1 through 66. Mode `0` encodes byte values 0 through 255; mode `1` decodes Ascii85 ASCII bytes.
- Four input bytes are interpreted as one unsigned big-endian 32-bit value and encoded as five base-85 digits, using ASCII `!` through `u` for digit values 0 through 84. A final partial input block is zero-padded on the right and emits one more character than its byte count. Empty input encodes to empty output.
- Decoding accepts only `!` through `u`, with full groups of five or a final group of two through four characters. A partial final group is padded with `u` digits and yields one fewer byte than its character count. Groups whose decoded value exceeds `2^32 - 1` are invalid.
- The contract omits Adobe `<~ ~>` wrappers, whitespace, and `z` shorthand. There is no separate padding syntax; ASCII `=` is an ordinary alphabet digit. Invalid mode, byte, symbol, group length, or overflowing group returns `-1`. Insufficient output capacity returns `-2`.
- The input is limited to 65 payload bytes; output is at most 82 encoded characters or 52 decoded bytes. Encoding and decoding take `O(n)` time and `O(1)` auxiliary space.

## Relationship to other candidates

This is distinct from `base64`: Base85 packs four bytes into five characters and shortens a final partial block without `=` padding; Base64 packs three bytes into four characters and uses RFC 4648 padding. It is also distinct from the radix-conversion benchmarks, which convert scalar digit sequences rather than arbitrary byte streams.

The pinned Rust and Python files both describe the `!`-to-`u` Ascii85 alphabet and the four-byte/five-character packing. Their base-conversion helper returns an empty digit string for numeric zero, so zero-valued blocks are not represented correctly; a final all-zero partial block also causes the Rust encoder's trim calculation to underflow. The Python source decodes input as UTF-8 before encoding and converts decoded values through Unicode, which does not preserve arbitrary bytes. These ports implement the bounded byte contract above, including zero blocks and all 256 byte values.

- [Rust `base85.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74a939ec5163648458a8c2b46fd4c/src/ciphers/base85.rs)
- [Python `base85.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/base85.py)
- [Existing Base64 benchmark](../base64/README.md)

## Workload and recording

The cases cover empty data, the upstream `12345` and `base 85` examples, a zero block, mixed binary bytes, a partial high-byte block, malformed symbols and lengths, and a group that overflows 32 bits. The nine ports use the shared `i64_array_bytes_output` ABI.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm base85 --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/b/base85/rust/build.json
```
