# IDEA single-block encrypt/decrypt

This package adapts the IDEA encryption kernel described by NBench BYTEmark into a fixed-key, single-block call. It is a deterministic algorithm kernel, not an NBench performance result.

## Contract

The `i64_array_bytes_output` input is exactly twelve signed 64-bit integers: eight 16-bit key words `[K0..K7]` followed by four 16-bit plaintext words `[P0..P3]`. Every word must be in `0..=65535`. IDEA expands the 128-bit key to 52 subkeys, encrypts the 64-bit block, and decrypts that ciphertext. The output contains the four ciphertext words followed by the four recovered plaintext words, each encoded as little-endian unsigned 16-bit bytes. Success returns 16. Invalid input returns `-1`; null output or capacity below 16 returns `-2`. The result is staged before writing, so errors leave the output untouched.

The known-vector workload uses key `00010002000300040005000600070008`, plaintext `0000000100020003`, and ciphertext `11FBED2B01986DE5`; the recovered plaintext must match the original block.

## Source and attribution

The source description is NBench BYTEmark's IDEA encryption kernel in [`nfinit/ansibench` at commit `ef90abd09d7b7bb1f2809f896d6f67fb9724bebe`](https://github.com/nfinit/ansibench/blob/ef90abd09d7b7bb1f2809f896d6f67fb9724bebe/nbench/src/nbench1.c). This implementation is written independently and does not copy source code. NBench BYTEmark's notice provides the source, executable, and documentation “as is” and disclaims warranties and liability. Preserve the notice and attribution when redistributing derived work. The notice is included as [NBENCH-LICENSE](NBENCH-LICENSE) and is also available at [`nbench/LICENSE` at the pinned commit](https://github.com/nfinit/ansibench/blob/ef90abd09d7b7bb1f2809f896d6f67fb9724bebe/nbench/LICENSE).

## Workload and oracle

[`workload.json`](workload.json) includes the known IDEA vector and malformed-input/output cases. The independent oracle is [`benchmarks/idea_encrypt_decrypt_oracle.py`](../../idea_encrypt_decrypt_oracle.py).

| Language | Port |
|---|---|
| C | [`c/i/idea_encrypt_decrypt.c`](../../../c/i/idea_encrypt_decrypt.c) |
| C++ | [`cpp/i/idea_encrypt_decrypt.cpp`](../../../cpp/i/idea_encrypt_decrypt.cpp) |
| C3 | [`c3/i/idea_encrypt_decrypt.c3`](../../../c3/i/idea_encrypt_decrypt.c3) |
| Elisa | [`elisa/i/idea_encrypt_decrypt.elisa`](../../../elisa/i/idea_encrypt_decrypt.elisa) |
| Nim | [`nim/i/idea_encrypt_decrypt.nim`](../../../nim/i/idea_encrypt_decrypt.nim) |
| Odin | [`odin/i/idea_encrypt_decrypt.odin`](../../../odin/i/idea_encrypt_decrypt.odin) |
| Rust | [`rust/i/idea_encrypt_decrypt.rs`](../../../rust/i/idea_encrypt_decrypt.rs) |
| V | [`v/i/idea_encrypt_decrypt.v`](../../../v/i/idea_encrypt_decrypt.v) |
| Zig | [`zig/i/idea_encrypt_decrypt.zig`](../../../zig/i/idea_encrypt_decrypt.zig) |
