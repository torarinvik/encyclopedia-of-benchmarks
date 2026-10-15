# Porta cipher

This benchmark preserves the pinned Python Porta tableau cipher. Each key letter selects one of 13 paired alphabets: `A/B`, `C/D`, through `Y/Z`. The transformation swaps the two halves of the selected tableau, so encryption and decryption use the same operation.

## Contract

- Input is `[mode, text_length, key_length, text_bytes..., key_bytes...]`. Mode `0` encrypts and mode `1` decrypts; both apply the same reciprocal mapping. Text length is `0..1024`, key length is `0..64`, and nonempty text requires a nonempty key.
- Text and key accept ASCII `A..Z` or `a..z`. Both are normalized to uppercase. The key repeats once per text character, including every letter; output is uppercase and has the same length as text.
- For a key letter, the pair index is `floor((key_letter - A) / 2)`. In the selected tableau, the `N..Z` row is rotated by that index. Letters `A..M` map into that row; letters `N..Z` map back into `A..M`. The mapping is an involution for each key position.
- Invalid mode, shape, empty key with nonempty text, or unsupported bytes return `-1`; insufficient output capacity returns `-2`. Output has no terminating NUL.

This differs from Vigenère's repeating additive shifts, Beaufort's arithmetic subtraction/addition, and Autokey's plaintext-based key extension. Porta selects one of 13 reciprocal paired substitution alphabets for each repeated key character. The source requires alphabetic input; unlike Vigenère, it does not preserve punctuation or spaces.

## Workload

[`workload.json`](workload.json) covers the pinned `marvin` / `jessica` example in both directions, reciprocal behavior, key-pair equivalence, case normalization, key repetition, long keys, maximum lengths, and malformed inputs.

## Reviewed source

- [Python `porta_cipher.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/porta_cipher.py)

Build with the `i64_array_bytes_output` ABI family and record with `benchmarks/run_i64_array_bytes_output.py`.
