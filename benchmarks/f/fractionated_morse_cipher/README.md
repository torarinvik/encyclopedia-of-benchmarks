# Fractionated Morse cipher

This benchmark preserves the pinned Python fractionated Morse mapping. It encodes letters as Morse, separates each plaintext character with `x` (spaces contribute an empty Morse code), groups the resulting stream into trigraphs, then maps those trigraphs through a keyword-ordered alphabet.

## Contract

- Input is `[mode, text_length, key_length, text_bytes..., key_bytes...]`. Mode `0` encrypts; mode `1` decrypts. Text and ciphertext lengths are bounded at 256 bytes; keys are bounded at 64 bytes. An empty key selects the normal `A..Z` order.
- Keys are ASCII letters in either case. Encryption text accepts ASCII letters in either case and literal spaces; it is uppercased before Morse encoding. Decryption accepts uppercase ASCII ciphertext letters only and returns uppercase plaintext.
- The keyed alphabet is the key uppercased with repeated letters removed in first-seen order, followed by the unused letters from `A..Z`. Trigraph symbols are ordered by the source's `...`, `..-`, `..x`, ..., `xxx` table. Encryption always pads by `3 - (morse_length mod 3)` `x` symbols, including three when already divisible by three. The `xxx` trigraph maps to the empty string.
- During decryption, trigraphs are split on `x`; empty Morse groups become spaces. The source strips leading and trailing spaces from decoded plaintext. Ciphertext that produces a non-Morse group is invalid here and returns `-1` (the Python source raises a dictionary lookup error). Invalid mode, shape, alphabet, or length also returns `-1`; insufficient output capacity returns `-2`. Output is raw ASCII without a NUL terminator.

This is distinct from plain Morse encoding, which emits a dot/dash code per character with separators and has no key or trigraph mapping. It is also distinct from a simple substitution cipher: fractionated Morse converts a variable-length Morse stream to keyed three-symbol groups before emitting ciphertext letters.

## Workload

[`workload.json`](workload.json) covers the source's `DEFEND THE EAST` / `ROUNDTABLE` example in both directions, key ordering and case, empty keys, padding, spaces, malformed inputs, and maximum lengths.

## Reviewed source

- [Python `fractionated_morse_cipher.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/fractionated_morse_cipher.py)
- [Plain Morse code contract](../../m/morse_code/README.md)

Build with the `i64_array_bytes_output` ABI family and record with `benchmarks/run_i64_array_bytes_output.py`.
