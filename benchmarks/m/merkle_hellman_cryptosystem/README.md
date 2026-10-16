# Merkle-Hellman Cryptosystem

This benchmark ports one-byte key generation, encryption, and decryption from the pinned Ruby source. Explicit random draws replace the source's global RNG so every call is deterministic.

## Contract

- Input is [message_byte, weight_rand[8], modulus_rand, a_draw_count, a_draws[a_draw_count]].
- The packed input contains exactly 11 + a_draw_count signed 64-bit values.
- The message byte is ASCII 0 through 127. Each weight and modulus draw is in 0 through 2^32-1; each multiplier draw is in the source's inclusive range 0 through the generated modulus.
- The eight private weights start from 2^32 and follow the source's superincreasing recurrence. The modulus is the final sum plus the supplied modulus draw. The multiplier draws must include every rejected non-coprime candidate in order, followed by the first coprime candidate; the draw count is 1 through 32.
- The source public weights are (a*x) mod n. Encryption uses the source's bit order for one byte. Decryption uses the modular inverse and greedy reverse knapsack traversal.
- Output is [ciphertext i64le, decoded_length i64le, decoded_byte]. A successful call returns 17. Invalid input or draw sequence returns -1; a null or short output buffer returns -2 without writing.

The independent oracle is [merkle_hellman_cryptosystem_oracle.py](../../merkle_hellman_cryptosystem_oracle.py). The workload covers multiple ASCII bytes, rejection sampling, malformed draw traces, invalid bounds, and short capacity.

## Pinned source

[TheAlgorithms/Ruby ciphers/merkle_hellman_cryptosystem.rb](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/ciphers/merkle_hellman_cryptosystem.rb), commit bda11bdfd83b7958e1ca98247e5e43100ca88865, class MerkleHellman.

## Implementations

| Language | Source |
| --- | --- |
| C | [merkle_hellman_cryptosystem.c](../../../c/m/merkle_hellman_cryptosystem.c) |
| C3 | [merkle_hellman_cryptosystem.c3](../../../c3/m/merkle_hellman_cryptosystem.c3) |
| C++ | [merkle_hellman_cryptosystem.cpp](../../../cpp/m/merkle_hellman_cryptosystem.cpp) |
| Elisa | [merkle_hellman_cryptosystem.elisa](../../../elisa/m/merkle_hellman_cryptosystem.elisa) |
| Nim | [merkle_hellman_cryptosystem.nim](../../../nim/m/merkle_hellman_cryptosystem.nim) |
| Odin | [merkle_hellman_cryptosystem.odin](../../../odin/m/merkle_hellman_cryptosystem.odin) |
| Rust | [merkle_hellman_cryptosystem.rs](../../../rust/m/merkle_hellman_cryptosystem.rs) |
| V | [merkle_hellman_cryptosystem.v](../../../v/m/merkle_hellman_cryptosystem.v) |
| Zig | [merkle_hellman_cryptosystem.zig](../../../zig/m/merkle_hellman_cryptosystem.zig) |
