# simple_keyword_cypher_decipher

This package ports the pinned Python `simple_keyword_cypher.decipher` operation. It is measured separately from the opposite direction, matching the source's separate functions.

## Contract

- Input is `[key_length, message_length, key_bytes..., message_bytes...]`. The key contains at most 64 ASCII letters; the message contains at most 256 ASCII bytes (`0..127`). The selected benchmark identity fixes the operation.
- The source uppercases the key and keeps each letter's first occurrence, then appends unused A–Z letters in order. Message lowercase ASCII letters are uppercased before substitution; all other ASCII bytes, including NUL, controls, spaces, and punctuation, pass through unchanged.
- The bounded contract restricts keys to ASCII letters and messages to ASCII. This excludes source behavior for Unicode `isalpha()` and non-ASCII uppercasing. Empty keys and messages are valid; repeated key letters are accepted and deduplicated.
- Malformed input returns `-1`. Success returns the output byte count and writes an ASCII byte string of the same length as the message. Insufficient capacity or a null output pointer returns `-2`.

The independent oracle is [`benchmarks/simple_keyword_cypher_decipher_oracle.py`](../../simple_keyword_cypher_decipher_oracle.py); its workload covers the pinned example, duplicates/case normalization, passthrough bytes, invalid shapes/values, maximum lengths, and capacity boundaries.

Pinned source: [TheAlgorithms/Python `simple_keyword_cypher.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/simple_keyword_cypher.py), commit `e1a2a8b016001309a73d5fec4818c35cca139795`.

Build and record with:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm simple_keyword_cypher_decipher --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm simple_keyword_cypher_decipher
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/simple_keyword_cypher_decipher.c`](../../../c/s/simple_keyword_cypher_decipher.c) |
| C3 | [`c3/s/simple_keyword_cypher_decipher.c3`](../../../c3/s/simple_keyword_cypher_decipher.c3) |
| C++ | [`cpp/s/simple_keyword_cypher_decipher.cpp`](../../../cpp/s/simple_keyword_cypher_decipher.cpp) |
| Elisa | [`elisa/s/simple_keyword_cypher_decipher.elisa`](../../../elisa/s/simple_keyword_cypher_decipher.elisa) |
| Nim | [`nim/s/simple_keyword_cypher_decipher.nim`](../../../nim/s/simple_keyword_cypher_decipher.nim) |
| Odin | [`odin/s/simple_keyword_cypher_decipher.odin`](../../../odin/s/simple_keyword_cypher_decipher.odin) |
| Rust | [`rust/s/simple_keyword_cypher_decipher.rs`](../../../rust/s/simple_keyword_cypher_decipher.rs) |
| V | [`v/s/simple_keyword_cypher_decipher.v`](../../../v/s/simple_keyword_cypher_decipher.v) |
| Zig | [`zig/s/simple_keyword_cypher_decipher.zig`](../../../zig/s/simple_keyword_cypher_decipher.zig) |
