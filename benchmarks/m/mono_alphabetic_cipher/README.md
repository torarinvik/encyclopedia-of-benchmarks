# Monoalphabetic cipher with a supplied alphabet

This benchmark follows the pinned PHP `MonoAlphabeticCipher` helper. It maps
letters between a supplied uppercase alphabet and key, preserves each
letter's case, copies spaces, and removes decimal digits before substitution.

## Contract

- ABI: `i64_array_scalar`.
- Input is `[operation, text_length, key_ascii[26], alphabet_ascii[26], text_ascii[text_length]]`.
  Operation 0 encrypts by mapping from `alphabet` to `key`; operation 1 decrypts
  by swapping those roles. Both 26-byte strings must be uppercase permutations
  of `A` through `Z`.
- Text has 0 through 128 ASCII bytes from letters, spaces, and decimal digits.
  Digits are removed, spaces are copied, and letters are looked up without
  regard to case; the output letter preserves the input letter's case. The
  packed input length must be exactly `54 + text_length`.
- Malformed input returns `-1`. Empty input is valid, as is a text containing
  only digits (which produces an empty output).
- The scalar result is the low 63 bits of standard FNV-1a-64 over an eight-byte
  little-endian unsigned output length followed by the transformed ASCII
  bytes. This fixed-width prefix also represents the empty output unambiguously.

The PHP helper does not require the key and alphabet to be permutations. The
benchmark does so to make every letter lookup defined and one-to-one.

[`workload.json`](workload.json) covers encryption/decryption, mixed case,
spaces, removed digits, empty outputs, maximum length, and malformed keys,
text, and framing. The independent oracle is
[`benchmarks/mono_alphabetic_cipher_oracle.py`](../../mono_alphabetic_cipher_oracle.py).

## Pinned source

- [TheAlgorithms/PHP `MonoAlphabeticCipher.php`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Ciphers/MonoAlphabeticCipher.php)
  at commit `b8a54469cc36332ef2934101b58d71075ef1d78e`.

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm mono_alphabetic_cipher --language rust
python3 benchmarks/run_i64_array_scalar.py --algorithm mono_alphabetic_cipher
python3 benchmarks/verify_i64_array_scalar.py --algorithm mono_alphabetic_cipher
```

## Implementations

| Language | Source |
|---|---|
| C | [`c/m/mono_alphabetic_cipher.c`](../../../c/m/mono_alphabetic_cipher.c) |
| C3 | [`c3/m/mono_alphabetic_cipher.c3`](../../../c3/m/mono_alphabetic_cipher.c3) |
| C++ | [`cpp/m/mono_alphabetic_cipher.cpp`](../../../cpp/m/mono_alphabetic_cipher.cpp) |
| Elisa | [`elisa/m/mono_alphabetic_cipher.elisa`](../../../elisa/m/mono_alphabetic_cipher.elisa) |
| Nim | [`nim/m/mono_alphabetic_cipher.nim`](../../../nim/m/mono_alphabetic_cipher.nim) |
| Odin | [`odin/m/mono_alphabetic_cipher.odin`](../../../odin/m/mono_alphabetic_cipher.odin) |
| Rust | [`rust/m/mono_alphabetic_cipher.rs`](../../../rust/m/mono_alphabetic_cipher.rs) |
| V | [`v/m/mono_alphabetic_cipher.v`](../../../v/m/mono_alphabetic_cipher.v) |
| Zig | [`zig/m/mono_alphabetic_cipher.zig`](../../../zig/m/mono_alphabetic_cipher.zig) |
