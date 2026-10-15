# Beaufort cipher candidate

This benchmark preserves the pinned Python implementation in `ciphers/beaufort_cipher.py`. Its name is Beaufort, but its encryption expression is `plaintext_index - key_index` modulo 26, and its inverse adds the key to the ciphertext. The textbook reciprocal Beaufort expression `key - plaintext` is not what this source implements.

## Contract

- Input is `[mode, text_length, key_length, text_bytes..., key_bytes...]`. Mode `0` encrypts; mode `1` decrypts. Text length is `0..1024`; a nonempty text requires an uppercase `A..Z` primer with length `1..text_length`. Empty text accepts only an empty key.
- Text accepts uppercase ASCII letters and literal spaces. Keys accept uppercase ASCII letters only. Lowercase, punctuation, and other bytes are invalid because the source indexes an uppercase alphabet dictionary directly.
- The primer repeats cyclically. Literal spaces are copied and do not advance the key position. Encryption maps each letter with `(plaintext - key) mod 26`; decryption maps with `(ciphertext + key) mod 26`. Output preserves spaces and has the same length as text.
- The source's key expansion does not terminate when the key is longer than the message; those inputs are outside the contract. Invalid input returns `-1`; insufficient output capacity returns `-2`. Output has no terminating NUL.

This differs from the existing Vigenère benchmark, which adds the key during encryption and subtracts it during decryption. It also differs from Autokey, which extends the key with plaintext instead of repeating the primer. The input contract captures the pinned Python source's supported uppercase-and-space domain and key cursor behavior.

## Workload

[`workload.json`](workload.json) covers the pinned German-attack example in both directions, reciprocal arithmetic checks, key repetition, spaces, empty input, maximum text and key lengths, malformed layouts, and unsupported characters or key sizes.

## Reviewed source

- [Python `beaufort_cipher.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/beaufort_cipher.py)

Build with the `i64_array_bytes_output` ABI family and record with `benchmarks/run_i64_array_bytes_output.py`.
