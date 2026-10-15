# Vernam cipher

This benchmark represents the alphabetic Vernam operation shared by the pinned Rust and Python sources: add or subtract a repeating key over `A..Z`, wrapping modulo 26. It is distinct from the Python `onepad_cipher` arithmetic transform and Java `OneTimePadCipher` bytewise XOR operation.

## Contract

- Input is `[mode, text_length, key_length, text_bytes..., key_bytes...]`. Mode `0` encrypts and mode `1` decrypts. Text length is `0..1024`; key length is `1..1024`; text and key bytes must be uppercase ASCII `A..Z`.
- The key repeats from its first byte whenever it is shorter than the text. Encryption adds key positions and decryption subtracts them modulo 26. Output is uppercase ASCII and has the same length as the text.
- Invalid input returns `-1`; insufficient output capacity returns `-2`. The key is required even for empty text, giving the Rust and Python implementations one shared supported domain.

The uppercase-letter contract is the intersection of the pinned source behavior: Python applies arithmetic directly to string code points, while Rust uppercases and filters to ASCII letters before applying the same repeating-key arithmetic. Inputs outside `A..Z` are outside this benchmark contract.

## Source mapping

- Rust `vernam` and Python `vernam_cipher` map to this benchmark on the shared `A..Z` domain.
- Python `onepad_cipher` is separate: it emits randomized integer ciphertext/key arrays using `(character + key) * key`.
- Java `one_time_pad_cipher` is separate: it XORs arbitrary byte arrays with an equal-length key and includes random-key generation.

[`workload.json`](workload.json) includes the source example, both directions, key cycling, empty text with a valid key, malformed layouts, invalid alphabets, and maximum text/key sizes.

## Reviewed sources

- [Rust `vernam.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/ciphers/vernam.rs)
- [Python `vernam_cipher.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/vernam_cipher.py)
- [Python `onepad_cipher.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/onepad_cipher.py)
- [Java `OneTimePadCipher.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/ciphers/OneTimePadCipher.java)

Build with the `i64_array_bytes_output` ABI family and record with `benchmarks/run_i64_array_bytes_output.py`.
