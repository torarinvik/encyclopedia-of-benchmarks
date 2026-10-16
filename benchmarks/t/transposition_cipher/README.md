# Transposition Cipher

This benchmark measures the reusable Route transposition helpers from the pinned Python source. It excludes the interactive CLI and its trailing `|` marker.

## Contract

- Input is a signed 64-bit array packed as `[mode, key, n, ascii_bytes...]`, with exact length `3 + n`.
- Mode `0` encrypts and mode `1` decrypts. `n` is 3 through 256 and `key` is at least 2 and less than `n`.
- Each message byte must be in `[0, 127]`; spaces and control bytes are preserved as message data.
- Encryption reads the message at indices `column, column + key, ...` for columns from 0 through `key - 1`. Decryption mirrors the source by distributing ciphertext bytes across `ceil(n / key)` columns, with the final shaded column shortened, then concatenating those columns.
- Valid calls return exactly `n` raw bytes. Invalid input returns `-1`; a null output pointer or capacity below `n` returns `-2`. No terminator or CLI `|` byte is appended. Output workspace is 256 bytes.

## Workload and implementation

[`workload.json`](workload.json) covers the pinned Python example, encryption and decryption with uneven columns, boundary keys, ASCII control and high bytes, and invalid headers, lengths, and message bytes. All nine ports use the `i64_array_bytes_output` ABI family.

The ports validate the entire packed input before writing output. Encryption follows the source's stride-by-key column traversal. Decryption computes each plaintext column's length and writes the ciphertext symbols into those columns in the same order as the Python loop.

## Upstream source

[Python `transposition_cipher.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/transposition_cipher.py)

The separate `transposition_cipher_encrypt_decrypt_file` source is an alias of these helpers and is not a separate benchmark package.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/t/transposition_cipher.c`](../../../c/t/transposition_cipher.c) |
| C3 | [`c3/t/transposition_cipher.c3`](../../../c3/t/transposition_cipher.c3) |
| C++ | [`cpp/t/transposition_cipher.cpp`](../../../cpp/t/transposition_cipher.cpp) |
| Elisa | [`elisa/t/transposition_cipher.elisa`](../../../elisa/t/transposition_cipher.elisa) |
| Nim | [`nim/t/transposition_cipher.nim`](../../../nim/t/transposition_cipher.nim) |
| Odin | [`odin/t/transposition_cipher.odin`](../../../odin/t/transposition_cipher.odin) |
| Rust | [`rust/t/transposition_cipher.rs`](../../../rust/t/transposition_cipher.rs) |
| V | [`v/t/transposition_cipher.v`](../../../v/t/transposition_cipher.v) |
| Zig | [`zig/t/transposition_cipher.zig`](../../../zig/t/transposition_cipher.zig) |
