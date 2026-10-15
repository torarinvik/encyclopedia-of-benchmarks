# One-time pad cipher

Encrypt or decrypt bytes by XORing each input byte with the corresponding key byte. The pinned Java implementation uses the same XOR operation for both directions and requires the key length to equal the data length.

## Contract

- Input is `[mode, length, data..., key...]`, with equal `length`-element data and key arrays. Mode `0` encrypts plaintext bytes; mode `1` decrypts ciphertext bytes.
- Length is `0..1024`; each data and key value is an unsigned byte in `0..255`.
- Output contains `data[i] XOR key[i]` as raw bytes. Empty data and key arrays are valid.
- Invalid mode, shape, or byte value returns `-1`; insufficient output capacity returns `-2`.
- Runtime is `O(n)` with `O(1)` auxiliary space.

The Java class also exposes random key generation. The benchmark measures the deterministic encrypt/decrypt transform with the key supplied in the input, so random key generation is outside the timed operation. As in the source, decryption is identical to encryption because XOR is its own inverse.

## Relationship to other ciphers

This bytewise XOR operation is distinct from [`vernam_cipher`](../../v/vernam_cipher/README.md), which works on uppercase ASCII letters with repeating-key modulo-26 addition/subtraction, and from `onepad_cipher`, which applies the Python source's `(character + key) * key` transform.

## Workload and recording

Cases include the same XOR transform in both directions, zero keys, binary values, empty input, and invalid shapes and bytes. All nine ports use `i64_array_bytes_output`.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm one_time_pad_cipher --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/o/one_time_pad_cipher/rust/build.json
```

## Pinned source

- [Java `OneTimePadCipher.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/ciphers/OneTimePadCipher.java)
- [Vernam cipher contract](../../v/vernam_cipher/README.md)
- [Arithmetic onepad contract](../onepad_cipher/README.md)
