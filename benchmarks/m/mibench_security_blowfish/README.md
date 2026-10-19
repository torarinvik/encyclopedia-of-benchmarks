# MiBench security-blowfish

This package ports the pinned MiBench Blowfish primitive for one 64-bit ECB
block. It supports encryption and decryption with the two fixed test keys in
`bftest.c`, so the profile exercises key expansion as well as the block round
function in every call. The ports are modified derivatives of Eric Young's
implementation and remain under the upstream terms reproduced in
[`LICENSE.txt`](LICENSE.txt). The attribution condition applies; this package
includes the required acknowledgment: “This product includes cryptographic
software written by Eric Young (eay@mincom.oz.au)”. The upstream terms must not
be changed or replaced with another license.

## Bounded contract

Export `mibench_security_blowfish` using the `i64_array_bytes_output` ABI.
Input contains exactly ten signed 64-bit values:

`[direction, key_selector, block_byte_0, ..., block_byte_7]`

`direction` is `0` for encryption or `1` for decryption. `key_selector` is `0`
for `abcdefghijklmnopqrstuvwxyz` or `1` for `Who is John Galt?`. The eight
block bytes and the result use big-endian order, matching `BF_ecb_encrypt`.
Each byte must be in `0..255`. Malformed input returns `-1` before output
checks. Null output or capacity below eight bytes returns `-2` without writes.
Success returns `8` and writes exactly one block.

The workload includes Eric Young's two published `bftest.c` ECB vectors in
both directions. The launcher invokes file encryption and includes CBC, CFB,
and OFB sources and behavior. Those file/CLI flows and modes are outside this
standalone ECB block profile, so the LAC-DCC coverage entry is Partial/related.

## Pinned source and license

- [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/security-blowfish/info.sh) selects the launcher source set and arguments.
- [`bf_enc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/security-blowfish/bf_enc.c), [`bf_skey.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/security-blowfish/bf_skey.c), [`bf_ecb.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/security-blowfish/bf_ecb.c), and [`bf_pi.h`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/security-blowfish/bf_pi.h) provide key setup, ECB byte ordering, the primitive, and initial P/S words.
- [`bftest.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/security-blowfish/bftest.c) supplies the key strings and known-answer blocks used in the workload.
- [`LICENSE.txt`](LICENSE.txt) reproduces the upstream Eric Young notice, conditions, disclaimer, advertising acknowledgment, and no-relicensing clause verbatim.
- [`workload.json`](workload.json) records the pin, ABI, bounds, and fixed cases. The independent [`mibench_security_blowfish_oracle.py`](../../mibench_security_blowfish_oracle.py) implements byte-oriented key expansion and ECB rounds.

## Ports

| Language | Port |
|---|---|
| C | [`c/m/mibench_security_blowfish.c`](../../../c/m/mibench_security_blowfish.c) |
| C3 | [`c3/m/mibench_security_blowfish.c3`](../../../c3/m/mibench_security_blowfish.c3) |
| C++ | [`cpp/m/mibench_security_blowfish.cpp`](../../../cpp/m/mibench_security_blowfish.cpp) |
| Elisa | [`elisa/m/mibench_security_blowfish.elisa`](../../../elisa/m/mibench_security_blowfish.elisa) |
| Nim | [`nim/m/mibench_security_blowfish.nim`](../../../nim/m/mibench_security_blowfish.nim) |
| Odin | [`odin/m/mibench_security_blowfish.odin`](../../../odin/m/mibench_security_blowfish.odin) |
| Rust | [`rust/m/mibench_security_blowfish.rs`](../../../rust/m/mibench_security_blowfish.rs) |
| V | [`v/m/mibench_security_blowfish.v`](../../../v/m/mibench_security_blowfish.v) |
| Zig | [`zig/m/mibench_security_blowfish.zig`](../../../zig/m/mibench_security_blowfish.zig) |
