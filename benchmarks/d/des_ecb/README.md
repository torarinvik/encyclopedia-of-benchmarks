# DES in ECB mode

This benchmark covers the shared DES block transform in the pinned Java `DES` and Python `des_ecb` sources. Both encrypt each 64-bit block independently with the standard DES initial permutation, 16 Feistel rounds, and final permutation. The Java source exposes ciphertext as a binary string and accepts a 64-character binary key; Python accepts a 16-character hexadecimal key and returns ciphertext as hexadecimal. This benchmark normalizes those text encodings to a 64-bit key value and raw ciphertext bytes.

## Contract

- Pack `[plaintext_byte_count, key_bits, ascii_byte_0, ...]` as signed 64-bit integers. Interpret the key value as a 64-bit two's-complement bit pattern.
- Plaintext length is `0..40` and each byte is ASCII (`0..127`).
- DES ignores the parity bits as specified by PC-1. Encrypt blocks independently in ECB mode.
- Append zero bytes to a final partial 8-byte block. Empty and block-aligned messages receive no extra block.
- Return raw ciphertext bytes and the ciphertext byte count. Invalid input returns `-1`; insufficient output capacity returns `-2`.

ASCII keeps Java's platform-dependent `String.getBytes()` behavior aligned with Python's character-to-byte bit conversion. The Python helper's random key generator is outside the encryption entry point; this contract supplies the key explicitly. The Java setter also leaves cached subkeys unchanged, so callers must construct with the selected key.

The Python source's hex formatting can omit leading zeroes in the combined ciphertext bit string; raw bytes in this contract preserve every 64-bit block exactly. The cryptographic core is the benchmark target.

The nine implementations use portable fixed-width integer shifts and table lookups, with no target-specific instructions. Build and record a port with the shared byte-output ABI, for example:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm des_ecb --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/d/des_ecb/rust/build.json
```

Verify with `python3 benchmarks/verify_i64_array_bytes_output.py --algorithm des_ecb`.

## Sources

- [TheAlgorithms/Java `DES.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/ciphers/DES.java), commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.
- [TheAlgorithms/Python `des_ecb.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/des_ecb.py), commit `e1a2a8b016001309a73d5fec4818c35cca139795`.
