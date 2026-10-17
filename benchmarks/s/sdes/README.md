# Simplified DES (S-DES)

This benchmark adapts the pinned interactive S-DES example to one bounded key/message pair. It keeps the source's fixed permutation and substitution tables, 10-bit key schedule, two Feistel rounds, and encryption/decryption round trip.

## Contract

- The packed `i64_array_bytes_output` input is exactly `[key, message]`. The key is an unsigned 10-bit value (`0..1023`), and the message is an unsigned byte (`0..255`); each value is interpreted at its fixed width, including leading zero bits.
- Key generation applies P10, rotates each 5-bit half left once for K1 and two more positions for K2, and applies P8 after each rotation stage.
- Encryption applies IP, `fk(K1)`, swaps the 4-bit halves, applies `fk(K2)`, then applies IP-inverse. The returned plaintext is produced by applying the same network with K2 and K1 in reverse order.
- Output is two bytes: `[ciphertext, recovered_plaintext]`. A valid call returns 2. A null input, malformed frame, or out-of-range value returns `-1`; a null output pointer or capacity below two bytes returns `-2` without writing.
- The workload pins the textbook vector key `1010000010`, message `11010111`, ciphertext `10101000`.

Source: [Python `sdes.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/other/sdes.py).

Build and record with the `i64_array_bytes_output` ABI family and `benchmarks/run_i64_array_bytes_output.py`.
