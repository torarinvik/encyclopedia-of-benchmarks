# Skytale cipher

This package ports the pinned Python `encrypt` and `decrypt` functions. Both directions preserve every character, including spaces and ASCII control bytes. The wrapper exposes the transform as a byte-output call.

## Contract

- ABI: `i64_array_bytes_output`; input is `[mode, key, text_length, ascii_code_units...]`. Mode `0` encrypts and mode `1` decrypts. The packed length must be exactly `3 + text_length`.
- `key` is 1 through 256, `text_length` is 0 through 256, and each code unit is ASCII 0 through 127. A null input pointer is invalid because the packed header is required.
- Encryption concatenates `plaintext[row::key]` for rows `0..key-1`. Decryption splits ciphertext into rows whose lengths are `floor(n/key)+1` for the first `n mod key` rows and `floor(n/key)` for the remaining rows, then interleaves those rows.
- Key 1 and text lengths less than or equal to the key produce the input unchanged, matching the source fast path. Empty text is valid for every supported key. Output is the transformed bytes with unchanged length and no terminator.
- Invalid input returns `-1` before output storage is checked. A null output pointer or a capacity below the output length returns `-2` without writes. A valid empty result still requires a nonnull output pointer; capacity zero is sufficient.

[`workload.json`](workload.json) covers the pinned doctest, encryption and decryption, ragged rows, spaces, control bytes, identity cases, empty input, null pointers, capacity boundaries, maximum input, and malformed values. The independent [oracle](../../skytale_cipher_oracle.py) returns exact output bytes and ABI statuses.

## Pinned source

- [TheAlgorithms/Python `skytale_cipher.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/skytale_cipher.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/skytale_cipher.c`](../../../c/s/skytale_cipher.c) |
| C3 | [`c3/s/skytale_cipher.c3`](../../../c3/s/skytale_cipher.c3) |
| C++ | [`cpp/s/skytale_cipher.cpp`](../../../cpp/s/skytale_cipher.cpp) |
| Elisa | [`elisa/s/skytale_cipher.elisa`](../../../elisa/s/skytale_cipher.elisa) |
| Nim | [`nim/s/skytale_cipher.nim`](../../../nim/s/skytale_cipher.nim) |
| Odin | [`odin/s/skytale_cipher.odin`](../../../odin/s/skytale_cipher.odin) |
| Rust | [`rust/s/skytale_cipher.rs`](../../../rust/s/skytale_cipher.rs) |
| V | [`v/s/skytale_cipher.v`](../../../v/s/skytale_cipher.v) |
| Zig | [`zig/s/skytale_cipher.zig`](../../../zig/s/skytale_cipher.zig) |
