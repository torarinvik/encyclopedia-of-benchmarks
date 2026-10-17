# RSA cipher single-character encryption

This benchmark covers raw RSA encryption of one ASCII character using a caller-supplied public key. Restricting the message to one character makes the Python byte-block representation and Rust Unicode-scalar representation agree exactly.

## Contract

The ABI is `i64_array_scalar`. Input is `[ascii_code, exponent, modulus]`. `ascii_code` is an integer from 0 through 127, the modulus is in `[128,65535]`, and the public exponent is an integer from 1 through `modulus-1`.

The Python `encrypt_message` routine ASCII-encodes the one-character string, packs it as one little-endian base-256 block, and returns `pow(block, exponent, modulus)`. For one ASCII byte, the block value is exactly `ascii_code`. Rust's `encrypt_text` converts the same character to its Unicode scalar and uses its square-and-multiply modular exponentiation routine, which yields the same result. Key generation, private-key decryption, file handling, and multi-character block packing are outside this workload. The caller supplies the public exponent and modulus; the source operation does not verify primality or key-pair membership.

Malformed framing or values outside the bounded domain return `-1`. Input length must be exactly 3 values. The result is one signed 64-bit ciphertext.

## Pinned sources

- Python `encrypt_message` and its block encoding: https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/rsa_cipher.py
- Rust `encrypt_text`, `encrypt`, and `mod_pow`: https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/ciphers/rsa_cipher.rs

## Workload and oracle

- Workload: [`workload.json`](workload.json)
- Oracle: [`rsa_cipher_oracle.py`](../../rsa_cipher_oracle.py)

## Ports

| Language | Source |
| --- | --- |
| C | [`c/r/rsa_cipher.c`](../../../c/r/rsa_cipher.c) |
| C3 | [`c3/r/rsa_cipher.c3`](../../../c3/r/rsa_cipher.c3) |
| C++ | [`cpp/r/rsa_cipher.cpp`](../../../cpp/r/rsa_cipher.cpp) |
| Elisa | [`elisa/r/rsa_cipher.elisa`](../../../elisa/r/rsa_cipher.elisa) |
| Nim | [`nim/r/rsa_cipher.nim`](../../../nim/r/rsa_cipher.nim) |
| Odin | [`odin/r/rsa_cipher.odin`](../../../odin/r/rsa_cipher.odin) |
| Rust | [`rust/r/rsa_cipher.rs`](../../../rust/r/rsa_cipher.rs) |
| V | [`v/r/rsa_cipher.v`](../../../v/r/rsa_cipher.v) |
| Zig | [`zig/r/rsa_cipher.zig`](../../../zig/r/rsa_cipher.zig) |
