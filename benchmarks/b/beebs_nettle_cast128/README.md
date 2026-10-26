# BEEBS Nettle CAST-128 one-block encryption

This package implements one CAST-128 encryption of a 64-bit block with a supplied 128-bit key. It follows the RFC 2144 key schedule and its 16-round variant for a 128-bit key. The mode is ECB for exactly one block, with no padding or chaining.

## Contract

The `i64_array_bytes_output` input contains exactly 24 bytes as signed 64-bit values in the range `0..=255`: `[key[16], plaintext_block[8]]`. Successful output is the eight ciphertext bytes and returns `8`. A malformed input returns `-1`; a null output or capacity below eight bytes returns `-2`, without writing. The maximum valid input length is 24; the parser accepts up to 25 values so an extra trailing byte is rejected explicitly.

The pinned BEEBS benchmark uses the fixed 16-byte key `0f0e...0100` and 16-byte plaintext `000102...0f`, then encrypts and decrypts both blocks in its timed function. This package projects that workload to a single encryption block; key setup and the round-trip decryption are outside this bounded operation. The workload preserves BEEBS's first block and also includes RFC 2144's 128-bit known-answer vector.

## Source and rights

Pinned BEEBS source: [`src/nettle-cast128/cast128.c`](https://github.com/mageec/beebs/blob/049ded9f3aeb5591f553879d3a0376b8614e9422/src/nettle-cast128/cast128.c), commit `049ded9f3aeb5591f553879d3a0376b8614e9422`, symbols `cast128_set_key`, `cast128_encrypt`, `initialise_benchmark`, `benchmark`, and `verify_benchmark`. The per-file header declares GPL-3.0-or-later and copyrights Niels Möller (2001, 2010, 2014) and Embecosm Limited and the University of Bristol (2014). Nettle's documentation credits the underlying CAST128 implementation to Steve Reid and describes it as public domain. These ports were independently written from the algorithm and S-box tables in [RFC 2144](https://datatracker.ietf.org/doc/html/rfc2144); they do not copy BEEBS or Nettle implementation text. RFC 2144 §3 states that the cipher is available royalty-free for commercial and non-commercial use. The complete source-rights note and GPL-3.0 license text are in [`LICENSE.txt`](LICENSE.txt).

This is a distinct block cipher from local AES/Rijndael, DES/3DES, Blowfish, IDEA, TEA, and stream-cipher packages.

See [workload](workload.json) and [oracle](../../beebs_nettle_cast128_oracle.py).

| Language | Port |
|---|---|
| C | [beebs_nettle_cast128.c](../../../c/b/beebs_nettle_cast128.c) |
| C3 | [beebs_nettle_cast128.c3](../../../c3/b/beebs_nettle_cast128.c3) |
| C++ | [beebs_nettle_cast128.cpp](../../../cpp/b/beebs_nettle_cast128.cpp) |
| Elisa | [beebs_nettle_cast128.elisa](../../../elisa/b/beebs_nettle_cast128.elisa) |
| Nim | [beebs_nettle_cast128.nim](../../../nim/b/beebs_nettle_cast128.nim) |
| Odin | [beebs_nettle_cast128.odin](../../../odin/b/beebs_nettle_cast128.odin) |
| Rust | [beebs_nettle_cast128.rs](../../../rust/b/beebs_nettle_cast128.rs) |
| V | [beebs_nettle_cast128.v](../../../v/b/beebs_nettle_cast128.v) |
| Zig | [beebs_nettle_cast128.zig](../../../zig/b/beebs_nettle_cast128.zig) |
