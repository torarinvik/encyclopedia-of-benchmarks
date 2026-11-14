# BEEBS Nettle CAST-128 one-block encryption

This package implements one CAST-128 encryption of a 64-bit block with a supplied 128-bit key. It follows the RFC 2144 key schedule and its 16-round variant for a 128-bit key. The mode is ECB for exactly one block, with no padding or chaining.

## Contract

The `i64_array_bytes_output` input contains exactly 24 bytes as signed 64-bit values in the range `0..=255`: `[key[16], plaintext_block[8]]`. Successful output is the eight ciphertext bytes and returns `8`. A malformed input returns `-1`; a null output or capacity below eight bytes returns `-2`, without writing. The maximum valid input length is 24; the parser accepts up to 25 values so an extra trailing byte is rejected explicitly.

This fixed-size profile uses constant time and space with respect to its input:
each call performs one 128-bit key expansion and 16 cipher rounds. The S-box
tables and temporary key material are bounded independently of the input values.

The pinned BEEBS benchmark uses a fixed key and two plaintext blocks, then encrypts and decrypts both blocks in its timed function. This package projects that workload to a single encryption block and expands the supplied key on each call; the round-trip decryption is outside this bounded operation. Its valid workload input is independently chosen.

## Source and rights

Pinned BEEBS source: [`src/nettle-cast128/cast128.c`](https://github.com/mageec/beebs/blob/049ded9f3aeb5591f553879d3a0376b8614e9422/src/nettle-cast128/cast128.c), commit `049ded9f3aeb5591f553879d3a0376b8614e9422`, symbols `cast128_set_key`, `cast128_encrypt`, `initialise_benchmark`, `benchmark`, and `verify_benchmark`. The per-file header declares GPL-3.0-or-later and copyrights Niels Möller (2001, 2010, 2014) and Embecosm Limited and the University of Bristol (2014). Nettle's documentation credits the underlying CAST128 implementation to Steve Reid and describes it as public domain. These ports were independently written from the algorithm and S-box tables in [RFC 2144](https://datatracker.ietf.org/doc/html/rfc2144); they do not copy BEEBS or Nettle implementation text. RFC 2144 §3 states that the cipher is available royalty-free for commercial and non-commercial use. The complete source-rights note and GPL-3.0 license text are in [`LICENSE.txt`](LICENSE.txt).

This is a distinct block cipher from local AES/Rijndael, DES/3DES, Blowfish, IDEA, TEA, and stream-cipher packages.

**Static audit in progress:** The primary oracle's key schedule has been
corrected to use the newly generated key bytes and alternate the two subkey
selection patterns in RFC 2144 section 2.4. All nine existing language drafts
now carry those corrections; a Mojo draft now includes the Feistel rounds,
S-boxes, key expansion, and its ABI. Odin's subkey buffer type was
also corrected to 32-bit words. None has been verified against the corrected
oracle. Treat this package as incomplete until the ports and fixtures are
reviewed. No code has been run.

The pinned BEEBS file contains the first-block ciphertext as a commented-out
value; its active verification checks the decrypted plaintext instead. The
source-derived successful case, the RFC known-answer case, and its derived
error probes have been removed. For the independently chosen successful input,
the suite draft obtains the expected bytes from the local reference rather than
storing an external vector. That reference is unexecuted and does not provide
an independently verified known answer; cipher correctness remains unproven.
The verifier draft derives the corresponding expected output length from that
same reference when checking recorder metadata. Neither path has been run.

See [workload](workload.json) and [oracle](../../beebs_nettle_cast128_oracle.py).

| Language | Port |
|---|---|
| C | [beebs_nettle_cast128.c](../../../c/b/beebs_nettle_cast128.c) |
| C3 | [beebs_nettle_cast128.c3](../../../c3/b/beebs_nettle_cast128.c3) |
| C++ | [beebs_nettle_cast128.cpp](../../../cpp/b/beebs_nettle_cast128.cpp) |
| Elisa | [beebs_nettle_cast128.elisa](../../../elisa/b/beebs_nettle_cast128.elisa) |
| Mojo | [beebs_nettle_cast128.mojo](../../../mojo/b/beebs_nettle_cast128.mojo) |
| Nim | [beebs_nettle_cast128.nim](../../../nim/b/beebs_nettle_cast128.nim) |
| Odin | [beebs_nettle_cast128.odin](../../../odin/b/beebs_nettle_cast128.odin) |
| Rust | [beebs_nettle_cast128.rs](../../../rust/b/beebs_nettle_cast128.rs) |
| V | [beebs_nettle_cast128.v](../../../v/b/beebs_nettle_cast128.v) |
| Zig | [beebs_nettle_cast128.zig](../../../zig/b/beebs_nettle_cast128.zig) |
