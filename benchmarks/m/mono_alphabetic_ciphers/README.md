# Monoalphabetic cipher with preserved text symbols

This benchmark follows the pinned Python `translate_message` helpers over a
bounded printable-ASCII domain. It preserves case and leaves spaces,
punctuation, and digits unchanged. The source's mode names are preserved,
including its unusual direction: encryption applies the inverse key mapping,
while decryption applies the direct key substitution.

## Contract

- ABI: `i64_array_scalar`.
- Input is `[operation, text_length, key_ascii[26], text_ascii[text_length]]`.
  Operation 0 is the source's `encrypt_message`; it maps letters through the
  inverse of `key`. Operation 1 is `decrypt_message`; it maps letters through
  `key`. The key must be an uppercase permutation of `A` through `Z`.
- Text has 0 through 128 printable ASCII bytes (`0x20`–`0x7e`). Letters are
  mapped without regard to case and keep their original case. Every
  non-letter byte is copied unchanged. The packed input length must be exactly
  `28 + text_length`.
- Malformed input returns `-1`.
- The scalar result is the low 63 bits of standard FNV-1a-64 over an eight-byte
  little-endian unsigned output length followed by the transformed ASCII
  bytes. This fixed-width prefix also represents empty output unambiguously.

The operation directions follow the pinned wrappers, not a conventional
plaintext/ciphertext labeling: `encrypt_message` looks up each letter in the
key and emits the matching standard alphabet letter.

[`workload.json`](workload.json) covers both source modes, mixed case,
unchanged punctuation/digits, empty and maximum-length text, and malformed
keys, text, and framing. The independent oracle is
[`benchmarks/mono_alphabetic_ciphers_oracle.py`](../../mono_alphabetic_ciphers_oracle.py).

## Pinned source

- [TheAlgorithms/Python `mono_alphabetic_ciphers.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/mono_alphabetic_ciphers.py)
  at commit `e1a2a8b016001309a73d5fec4818c35cca139795`.

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm mono_alphabetic_ciphers --language rust
python3 benchmarks/run_i64_array_scalar.py --algorithm mono_alphabetic_ciphers
python3 benchmarks/verify_i64_array_scalar.py --algorithm mono_alphabetic_ciphers
```

## Implementations

| Language | Source |
|---|---|
| C | [`c/m/mono_alphabetic_ciphers.c`](../../../c/m/mono_alphabetic_ciphers.c) |
| C3 | [`c3/m/mono_alphabetic_ciphers.c3`](../../../c3/m/mono_alphabetic_ciphers.c3) |
| C++ | [`cpp/m/mono_alphabetic_ciphers.cpp`](../../../cpp/m/mono_alphabetic_ciphers.cpp) |
| Elisa | [`elisa/m/mono_alphabetic_ciphers.elisa`](../../../elisa/m/mono_alphabetic_ciphers.elisa) |
| Nim | [`nim/m/mono_alphabetic_ciphers.nim`](../../../nim/m/mono_alphabetic_ciphers.nim) |
| Odin | [`odin/m/mono_alphabetic_ciphers.odin`](../../../odin/m/mono_alphabetic_ciphers.odin) |
| Rust | [`rust/m/mono_alphabetic_ciphers.rs`](../../../rust/m/mono_alphabetic_ciphers.rs) |
| V | [`v/m/mono_alphabetic_ciphers.v`](../../../v/m/mono_alphabetic_ciphers.v) |
| Zig | [`zig/m/mono_alphabetic_ciphers.zig`](../../../zig/m/mono_alphabetic_ciphers.zig) |
