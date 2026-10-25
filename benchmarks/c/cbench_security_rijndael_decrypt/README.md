# cBench Rijndael AES-256 block decryption

This package implements the pinned cBench `aes.c::decrypt` block primitive for the decryption launcher variant. It is a distinct AES operation from the local MiBench package, which profiles `set_key(..., enc, ...)` and `encrypt` only. The `_d` and `_e` launcher trees share the same AES implementation (`aes.c` differs only in whitespace); `_d` selects decryption and `_e` selects encryption.

## Contract

Export `cbench_security_rijndael_decrypt` with the `i64_array_bytes_output` ABI. Input is exactly 48 signed-i64 values: 32 AES-256 key bytes followed by one 16-byte ciphertext block. Every value must be in `0..255`. Output is the 16-byte AES inverse-block result, before CBC XOR with the preceding ciphertext block or IV. Malformed input returns `-1` before output checks; null or short output capacity returns `-2` without writes; success returns 16.

The port builds the AES-256 encryption round-key schedule, constructs the inverse substitution table from the forward Rijndael S-box, and applies inverse ShiftRows/SubBytes, AddRoundKey, and inverse MixColumns for rounds 13 through 1, followed by the final inverse round. This is the standalone primitive called by the source's `aesxam` CBC file wrapper; chaining, file handling, padding, command line, and repeated-dataset profile are excluded.

## Pinned source and rights

- Repository: [`lac-dcc/Benchmarks`](https://github.com/lac-dcc/Benchmarks)
- Commit: `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`
- Decryption launcher: [`cBench/security_rijndael_d/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/security_rijndael_d/src/info.sh), building `aes.c` and `aesxam.c`; dataset entries select mode `d`.
- Kernel: [`cBench/security_rijndael_d/src/aes.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/security_rijndael_d/src/aes.c), symbol `decrypt`. The sibling [`security_rijndael_e`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/security_rijndael_e/src) uses the same core and license but selects CBC encryption.
- The complete Brian Gladman terms and disclaimer are retained in [`LICENSE.txt`](LICENSE.txt). They expressly permit modification and redistribution subject to the listed notice conditions. These are modified implementations; the changes and bounded scope are documented here.

[`workload.json`](workload.json) contains AES-256 inverse-block vectors, error cases, and capacity cases. [`cbench_security_rijndael_decrypt_oracle.py`](../../cbench_security_rijndael_decrypt_oracle.py) provides an independent byte-oriented inverse AES model.

| Language | Port |
|---|---|
| C | [`c/m/cbench_security_rijndael_decrypt.c`](../../../c/m/cbench_security_rijndael_decrypt.c) |
| C3 | [`c3/m/cbench_security_rijndael_decrypt.c3`](../../../c3/m/cbench_security_rijndael_decrypt.c3) |
| C++ | [`cpp/m/cbench_security_rijndael_decrypt.cpp`](../../../cpp/m/cbench_security_rijndael_decrypt.cpp) |
| Elisa | [`elisa/m/cbench_security_rijndael_decrypt.elisa`](../../../elisa/m/cbench_security_rijndael_decrypt.elisa) |
| Nim | [`nim/m/cbench_security_rijndael_decrypt.nim`](../../../nim/m/cbench_security_rijndael_decrypt.nim) |
| Odin | [`odin/m/cbench_security_rijndael_decrypt.odin`](../../../odin/m/cbench_security_rijndael_decrypt.odin) |
| Rust | [`rust/m/cbench_security_rijndael_decrypt.rs`](../../../rust/m/cbench_security_rijndael_decrypt.rs) |
| V | [`v/m/cbench_security_rijndael_decrypt.v`](../../../v/m/cbench_security_rijndael_decrypt.v) |
| Zig | [`zig/m/cbench_security_rijndael_decrypt.zig`](../../../zig/m/cbench_security_rijndael_decrypt.zig) |

No runtime or compiler verification is claimed.
