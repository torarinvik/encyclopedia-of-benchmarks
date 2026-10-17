# Rust multi-key transposition cipher

This package benchmarks the pinned Rust cipher's columnar transposition rounds. It remains separate from the Go single-key `transposition` benchmark and the Python `columnar_transposition` and `transposition_cipher` packages because its keys compose in sequence, each round filters and uppercases the message, and encryption groups the final ciphertext with spaces.

## Contract

The `i64_array_scalar` input is packed as:

```text
[mode, key_count, (key_length, key_ascii_bytes...)*, message_length, message_ascii_bytes...]
```

- `mode` is `0` for encryption and `1` for decryption.
- There are 1–4 keys. Each key contains 1–32 ASCII letters. Keys are passed to the pinned source joined with one ASCII space; the packed record stores each token separately.
- The message contains 1–256 ASCII bytes, including punctuation, digits, spaces, and ASCII control bytes. Every round uppercases it and keeps only `A`–`Z`.
- The normalized message must contain at least as many letters as the longest key. The pinned encryption routine can index a missing column when a key is longer than the filtered message, so this bound keeps both modes within the source's safe domain.
- Encryption applies keys in input order. Decryption applies them in reverse order. Duplicate key letters retain their original column order.
- Each encryption round reads ragged columns from the filtered message in alphabetical key order. It inserts a space after every `ceil(letter_count / key_length)` output letters and trims the final separator. Spaces from earlier rounds are removed by the next round's normalization. Decryption returns ungrouped uppercase letters.
- Invalid framing, modes, keys, message bytes, or the normalized-length bound return `-1`.
- The scalar result is the low 63 bits of FNV-1a-64 over the final output length as a little-endian `u64`, followed by each output ASCII codepoint as a little-endian `u32`. Encryption's final grouping spaces are included in the hash.

## Workload and source

[`workload.json`](workload.json) covers the pinned single- and double-key examples, encryption and decryption, duplicate and case-variant key letters, filtering, grouped output, the 32-letter key boundary, the 256-byte message boundary, and malformed records. [`transposition_rust_oracle.py`](../../transposition_rust_oracle.py) independently models the ragged columns and output hash frame.

Pinned source: [TheAlgorithms/Rust `transposition.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/ciphers/transposition.rs), symbol `transposition`.

| Language | Port |
|---|---|
| C | [`c/t/transposition_rust.c`](../../../c/t/transposition_rust.c) |
| C3 | [`c3/t/transposition_rust.c3`](../../../c3/t/transposition_rust.c3) |
| C++ | [`cpp/t/transposition_rust.cpp`](../../../cpp/t/transposition_rust.cpp) |
| Elisa | [`elisa/t/transposition_rust.elisa`](../../../elisa/t/transposition_rust.elisa) |
| Nim | [`nim/t/transposition_rust.nim`](../../../nim/t/transposition_rust.nim) |
| Odin | [`odin/t/transposition_rust.odin`](../../../odin/t/transposition_rust.odin) |
| Rust | [`rust/t/transposition_rust.rs`](../../../rust/t/transposition_rust.rs) |
| V | [`v/t/transposition_rust.v`](../../../v/t/transposition_rust.v) |
| Zig | [`zig/t/transposition_rust.zig`](../../../zig/t/transposition_rust.zig) |
