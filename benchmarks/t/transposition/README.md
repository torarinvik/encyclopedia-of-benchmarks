# Go transposition cipher

This package benchmarks the pinned Go transposition cipher's rune-block encryption and decryption. It is separate from the Rust `transposition_rust` candidate and from the existing Python `columnar_transposition` benchmark.

## Contract

The scalar `i64_array_scalar` input is `[mode, key_length, key_ascii..., text_length, text_ascii...]`. `mode` is `0` for encryption and `1` for decryption. The key has 1–32 ASCII letters; the text has 1–512 printable ASCII bytes. The exact input length is `3 + key_length + text_length` and cannot exceed 547 values. The Go source lowercases the key before ranking letters. Duplicate key letters retain their order in the ranked permutation.

Encryption rejects empty text, an empty key, and plaintext ending in a space. It appends `key_length - (text_length % key_length)` spaces, including a full extra block when the text length is already divisible by the key length. Each block is reordered by the stable alphabetical key ranks. Decryption rejects empty text and an empty key, pads a partial final block with spaces, applies the inverse rank order, and strips all trailing spaces from the result. Inputs outside these bounds or alphabet rules return `-1`.

The result is the low 63 bits of FNV-1a-64 over an unambiguous byte stream: output rune count as an unsigned 64-bit little-endian integer, followed by each ASCII rune as an unsigned 32-bit little-endian integer. This preserves Go's rune-oriented source behavior on the selected ASCII domain.

## Workload and source

[`workload.json`](workload.json) includes encrypt/decrypt cases, repeated key letters, exact-width padding, partial final blocks, spaces, and malformed inputs. The independent [oracle](../../transposition_oracle.py) returns `-1` for invalid records.

Pinned source: [TheAlgorithms/Go `transposition.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/cipher/transposition/transposition.go).

| Language | Port |
|---|---|
| C | [`c/t/transposition.c`](../../../c/t/transposition.c) |
| C3 | [`c3/t/transposition.c3`](../../../c3/t/transposition.c3) |
| C++ | [`cpp/t/transposition.cpp`](../../../cpp/t/transposition.cpp) |
| Elisa | [`elisa/t/transposition.elisa`](../../../elisa/t/transposition.elisa) |
| Nim | [`nim/t/transposition.nim`](../../../nim/t/transposition.nim) |
| Odin | [`odin/t/transposition.odin`](../../../odin/t/transposition.odin) |
| Rust | [`rust/t/transposition.rs`](../../../rust/t/transposition.rs) |
| V | [`v/t/transposition.v`](../../../v/t/transposition.v) |
| Zig | [`zig/t/transposition.zig`](../../../zig/t/transposition.zig) |
