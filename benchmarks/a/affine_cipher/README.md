# Affine Cipher

Encrypt or decrypt text using a supplied alphabet and the affine map `E(x) = (a*x + b) mod m`; decryption uses the modular inverse of `a`. The source repositories expose different alphabet sizes and key representations. This benchmark makes the alphabet explicit, so the printable-ASCII, uppercase-letter, and caller-defined variants share one contract.

## Contract

- Pack inputs as `[mode, a, b, alphabet_length, alphabet bytes..., text_length, text bytes...]`. Mode `0` encrypts; mode `1` decrypts.
- The alphabet contains 2 to 95 unique printable ASCII bytes (`32..126`). Every text byte must occur in the supplied alphabet. Output has the same length as the input text.
- The multiplier `a` is from 0 to 1,000,000 and must be coprime to the alphabet length. The additive key `b` is from 0 to `alphabet_length - 1`. Text length is at most 512 bytes.
- Invalid packed inputs return `-1`; insufficient output capacity returns `-2`.

## Workload and verification

[`workload.json`](workload.json) includes the 95-symbol printable-ASCII alphabet, A–Z, decimal digits, a custom punctuation alphabet, encryption/decryption pairs, empty input, and malformed keys/text. [`benchmarks/verify_affine_cipher.py`](../../verify_affine_cipher.py) compares all nine ports with modular arithmetic over exhaustive small alphabets, exhaustive A–Z keys, the full printable alphabet, deterministic random alphabets and messages, and invalid inputs.

The common algorithm appears in [TheAlgorithms C affine cipher](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/cipher/affine.c), [Julia affine transform](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/cipher/affine.jl), [Java AffineCipher](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/ciphers/AffineCipher.java), [JavaScript AffineCipher](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Ciphers/AffineCipher.js), [Python affine cipher](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/affine_cipher.py), and [Rust affine cipher](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/ciphers/affine_cipher.rs).

Build with the `i64_array_bytes_output` ABI family and record with `benchmarks/run_i64_array_bytes_output.py`.
