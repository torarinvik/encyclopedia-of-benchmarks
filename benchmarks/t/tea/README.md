# Tiny Encryption Algorithm (TEA)

This benchmark adapts the pinned Rust TEA block cipher to one 64-bit block and two 64-bit key words. It preserves the source's little-word-first decomposition, 32 rounds, wrapping 32-bit arithmetic, and decrypt round trip.

## Contract

- The packed `i64_array_bytes_output` input contains exactly six signed-i32 bit-pattern slots: `[block_low, block_high, key0_low, key0_high, key1_low, key1_high]`. Each pair is combined as `low_u32 | (high_u32 << 32)`; negative slots retain their low 32-bit pattern.
- Encryption runs 32 TEA rounds with delta `0x9E3779B9`, wrapping every word operation modulo `2^32`. The returned ciphertext is then decrypted with the same two key words.
- Output contains two unsigned 64-bit values as little-endian bytes: `[ciphertext, recovered_plaintext]`. A valid call returns 16. A null input, malformed frame, or slot outside the signed-i32 range returns `-1`; a null output pointer or capacity below 16 returns `-2` without writing.
- The zero block / zero key vector is pinned to the source's known ciphertext bytes `0A 3A EA 41 40 A9 BA 94`.

Source: [Rust `tea.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/ciphers/tea.rs).

Build and record with the `i64_array_bytes_output` ABI family and `benchmarks/run_i64_array_bytes_output.py`.
