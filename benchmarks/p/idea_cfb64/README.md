# IDEA CFB64 stream encryption and decryption

This package profiles IDEA in 64-bit cipher-feedback mode in both directions, using the pinned PGP `ideaCfbEncrypt` and `ideaCfbDecrypt` helpers. It differs from the repository's `idea_encrypt_decrypt` single-block ECB package by carrying the ciphertext block forward as feedback and handling a final partial block without padding.

## Contract

ABI: `i64_array_bytes_output`; symbol: `idea_cfb64`.

Input is `[mode, text_length, key_byte[16], iv_byte[8], data_byte[text_length]]`, with mode 0 for encryption and mode 1 for decryption, a 1–24 byte payload, and every byte in `0..255`. The IDEA block cipher reads key and IV words in big-endian byte order. For each block, encrypt the current 8-byte feedback state and XOR the next up-to-eight input bytes with that keystream prefix. Encryption feeds the produced ciphertext back; decryption feeds the input ciphertext back. A final partial block is emitted without padding. Maximum valid input is 50 words, maximum parseable input 51, and maximum output 24 bytes. Malformed input returns `-1`; null or insufficient output returns `-2`, after validation and with no writes on error.

## Source and rights

Sources: [`security_pgp_d/src/idea.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/security_pgp_d/src/idea.c) for encryption and [`security_pgp_e/src/idea.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/security_pgp_e/src/idea.c) for decryption, both at `lac-dcc/Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`; launchers are their corresponding `src/info.sh` files. The helpers are `ideaCipher`, `ideaCfbInit`, `ideaCfbEncrypt`, and `ideaCfbDecrypt`. Both source variants describe IDEA as developed by Xuejia Lai and James L. Massey and note Colin Plumb's optimizations. They state noncommercial use requires no license fee, while commercial users may need a patent license; neither provides an explicit source-code redistribution grant. These ports are independent implementations with no copied upstream code or comments. See [`NOTICE.txt`](NOTICE.txt) for the full rights caveat.

Independent oracle: [`idea_cfb64_oracle.py`](../../idea_cfb64_oracle.py). Workload fixtures include two full blocks plus a partial tail in both directions. No runtime, compiler, or validator verification is claimed.

## Ports

- C: [`c/p/idea_cfb64.c`](../../../c/p/idea_cfb64.c)
- C3: [`c3/p/idea_cfb64.c3`](../../../c3/p/idea_cfb64.c3)
- C++: [`cpp/p/idea_cfb64.cpp`](../../../cpp/p/idea_cfb64.cpp)
- Elisa: [`elisa/p/idea_cfb64.elisa`](../../../elisa/p/idea_cfb64.elisa)
- Nim: [`nim/p/idea_cfb64.nim`](../../../nim/p/idea_cfb64.nim)
- Odin: [`odin/p/idea_cfb64.odin`](../../../odin/p/idea_cfb64.odin)
- Rust: [`rust/p/idea_cfb64.rs`](../../../rust/p/idea_cfb64.rs)
- V: [`v/p/idea_cfb64.v`](../../../v/p/idea_cfb64.v)
- Zig: [`zig/p/idea_cfb64.zig`](../../../zig/p/idea_cfb64.zig)
