# Monoalphabetic substitution cipher

This benchmark implements the pinned Java `MonoAlphabetic` cipher over a
bounded uppercase ASCII domain. Encryption maps each plaintext letter to the
key letter at the same alphabet position. Decryption maps each ciphertext
letter back through the inverse key.

## Contract

- ABI: `i64_array_scalar`.
- Input is `[operation, text_length, key_0, ..., key_25, text_0, ...]`.
  `operation` is 0 for encryption and 1 for decryption. The key and text are
  ASCII codes: the key must be a permutation of `A` through `Z`, and text must
  contain 1 through 256 uppercase ASCII letters. The packed length must be
  exactly `28 + text_length`.
- Malformed input, a non-permutation key, or a non-uppercase text byte returns
  `-1`. The 1–256 text bound is the benchmark's bounded domain; in particular,
  encryption rejects empty text as the Java regex uses `[A-Z]+`.
- The scalar result is the low 63 bits of standard FNV-1a-64 over an eight-byte
  little-endian unsigned output length followed by the transformed uppercase
  ASCII bytes. The length prefix makes the byte stream unambiguous, including
  at the 256-character maximum.

The Java source does not validate the key as a permutation. The benchmark
requires a permutation so encryption and decryption have a single, defined
mapping for every letter.

[`workload.json`](workload.json) covers identity, QWERTY and reversed keys,
both operations, one-character and maximum-length inputs, and malformed keys,
text, and framing. The independent oracle is
[`benchmarks/mono_alphabetic_oracle.py`](../../mono_alphabetic_oracle.py).

## Pinned source

- [TheAlgorithms/Java `MonoAlphabetic.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/ciphers/MonoAlphabetic.java)
  at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm mono_alphabetic --language rust
python3 benchmarks/run_i64_array_scalar.py --algorithm mono_alphabetic
python3 benchmarks/verify_i64_array_scalar.py --algorithm mono_alphabetic
```

## Implementations

| Language | Source |
|---|---|
| C | [`c/m/mono_alphabetic.c`](../../../c/m/mono_alphabetic.c) |
| C3 | [`c3/m/mono_alphabetic.c3`](../../../c3/m/mono_alphabetic.c3) |
| C++ | [`cpp/m/mono_alphabetic.cpp`](../../../cpp/m/mono_alphabetic.cpp) |
| Elisa | [`elisa/m/mono_alphabetic.elisa`](../../../elisa/m/mono_alphabetic.elisa) |
| Nim | [`nim/m/mono_alphabetic.nim`](../../../nim/m/mono_alphabetic.nim) |
| Odin | [`odin/m/mono_alphabetic.odin`](../../../odin/m/mono_alphabetic.odin) |
| Rust | [`rust/m/mono_alphabetic.rs`](../../../rust/m/mono_alphabetic.rs) |
| V | [`v/m/mono_alphabetic.v`](../../../v/m/mono_alphabetic.v) |
| Zig | [`zig/m/mono_alphabetic.zig`](../../../zig/m/mono_alphabetic.zig) |
