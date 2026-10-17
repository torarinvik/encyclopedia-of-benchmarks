# Playfair cipher

This benchmark covers the shared Java and Python Playfair-cipher behavior on
bounded ASCII inputs. The operation builds the 5×5 key square, transforms
letter digraphs, and reduces the returned text to a deterministic 63-bit hash
for the scalar ABI.

## Contract

The `i64_array_scalar` input is
`[operation, key_length, key_bytes..., text_length, text_bytes...]`. Operation
`0` encrypts and operation `1` decrypts. Key and text bytes are uppercase ASCII
letters from `A` through `Z`, excluding `J`; the key length is 0–25, and
duplicate key letters are allowed. Text length is 0–128 and must be even.
For encryption, adjacent equal plaintext letters are rejected. Decryption
preserves every returned letter, including any `X` filler; it does not remove
fillers after decoding.

These restrictions make both pinned sources agree: key processing keeps the
first occurrence of each allowed key letter, then fills from
`ABCDEFGHIKLMNOPQRSTUVWXYZ`; the excluded `J` avoids Java's `J`→`I` rewrite,
and encryption inputs need no filler insertion or odd-length padding. Empty
text is valid in either mode. Invalid operations, shapes, lengths, or bytes
return `-1`.

The string result is hashed byte by byte with 64-bit FNV-1a, starting at
`14695981039346656037` and multiplying by `1099511628211` modulo `2^64` after
each XOR. Return the low 63 bits of the final hash as the scalar result. Thus
an empty result returns the low 63 bits of the FNV offset basis.

The maximum valid packed input contains 156 integers; 157 are parseable so a
trailing-value case can be rejected.

## Pinned sources

- TheAlgorithms/Java [`PlayfairCipher.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/ciphers/PlayfairCipher.java), methods `encrypt` and `decrypt`, commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`
- TheAlgorithms/Python [`playfair_cipher.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/ciphers/playfair_cipher.py), functions `encode` and `decode`, commit `e1a2a8b016001309a73d5fec4818c35cca139795`

## Workload and oracle

The workload is [`workload.json`](workload.json); the independent square,
digraph-transform, and hash oracle is
[`benchmarks/playfair_cipher_oracle.py`](../../playfair_cipher_oracle.py).
