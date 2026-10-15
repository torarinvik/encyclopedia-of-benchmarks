# Autokey cipher

This benchmark models the plaintext-autokey cipher shared by the pinned Java, Python, and C# sources. It extends the primer key with the plaintext, then applies modulo-26 addition or subtraction. Unlike standard Vigenère, the key does not repeat after the primer.

## Contract

- Input is `[mode, dialect, text_length, key_length, text_bytes..., key_bytes...]`. Mode `0` encrypts and mode `1` decrypts. Dialect `0` selects the Java/C# uppercase output; dialect `1` selects Python lowercase output.
- Text length and key length are each `1..1024`. The key is a nonempty ASCII-letter primer. Java/C# accept uppercase or lowercase text and keys. Python encryption accepts either case; Python decryption expects lowercase ciphertext because its source does not lowercase that argument. Keys are case-insensitive in all dialects.
- Encryption uses the primer followed by plaintext letters. Decryption uses the primer followed by recovered plaintext letters. The key is not repeated. Output length matches text length.
- The Java and C# sources return uppercase; Python returns lowercase. Invalid input returns `-1`; insufficient output capacity returns `-2`.

The contract restricts text and key to ASCII letters so all three sources have a shared alphabetic domain. Java and C# uppercase and remove nonletters from the text, while Python preserves nonletters and advances over key punctuation differently; those source-specific paths are outside this bounded contract. The Python decoder also processes lowercase letters only, so uppercase ciphertext is outside its supported dialect. Their key extension and encrypt/decrypt arithmetic agree on letters. The C# filename uses the misspelling `AutokeyEncorder`.

This is distinct from the existing Vigenère benchmark, which repeats the primer cyclically instead of extending it with plaintext.

## Source mapping

- Java `Autokey` and Python `autokey` map to this benchmark.
- C# `AutokeyEncorder` (`autokey_encorder` candidate) maps to the same benchmark under the uppercase dialect.

[`workload.json`](workload.json) covers both directions, key extension, keys longer than the text, mixed letter case, both output-case dialects, maximum lengths, and malformed inputs.

## Reviewed sources

- [Java `Autokey.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/ciphers/Autokey.java)
- [Python `autokey.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/autokey.py)
- [C# `AutokeyEncorder.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Encoders/AutokeyEncorder.cs)

Build with the `i64_array_bytes_output` ABI family and record with `benchmarks/run_i64_array_bytes_output.py`.
