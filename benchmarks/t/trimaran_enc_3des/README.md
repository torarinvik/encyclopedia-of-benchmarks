# Trimaran enc-3des (bounded 3-key stage)

This package exposes the pinned FIPS-46-3 DES/3DES block transform with the third (three-key) key profile from the Trimaran `enc-3des` source. It uses the source's three fixed NIST test keys. This distinct transform is not covered by local `des_ecb`, which implements only single-key DES.

## Contract

The `i64_array_bytes_output` ABI function `trimaran_enc_3des` accepts exactly nine signed 64-bit slots: direction (`0` encrypt, `1` decrypt), then eight block bytes in big-endian order. Every block byte must be in `0..255`. The fixed three keys are `0123456789abcdef`, `23456789abcdef01`, and `456789abcdef0123`. Encryption computes E(K1), D(K2), E(K3); decryption computes D(K3), E(K2), D(K1). DES parity bits are ignored by the standard key schedule.

Success returns 8 and writes one raw eight-byte block in big-endian order. Invalid input returns `-1`; a null output pointer or capacity below eight returns `-2`. Validation and the full transform happen before any output write, so failures leave output untouched. The function performs one bounded block transform (constant time/space with respect to input size).

This profile covers the standalone three-key 3DES ECB stage only. It does not model the launcher's single-DES or two-key variants, its 10,000-transform inner Monte Carlo loop, its 10/200 outer delay repeats, or the CLI report. The source launcher invokes `des.c` with `RUN_OPTIONS=10` for the small profile and `200` otherwise.

## Pinned provenance and license

- Launcher: [Trimaran/enc-3des/info.sh](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Trimaran/enc-3des/info.sh) at pinned commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`; it selects `des.c` and passes 10 or 200.
- Algorithm and fixed test vectors: [Trimaran/enc-3des/des.c](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Trimaran/enc-3des/des.c), same commit. The file identifies its FIPS-46-3 compliant implementation and includes the GPL-2.0-or-later grant and copyright notice.
- Full GPL text: [`LICENSE-GPL-2.0-or-later.txt`](LICENSE-GPL-2.0-or-later.txt); retained source notice: [`LICENSE_NOTICE.txt`](LICENSE_NOTICE.txt).

## Workload

[`workload.json`](workload.json) pins the source's fixed 3-key encrypt and decrypt test blocks, plus a bounded non-source block and malformed/capacity cases. Inputs are normalized from bytes to signed 64-bit words; output is raw bytes rather than the source program's human-readable status report.

## Ports

| Language | File |
| --- | --- |
| C | [`c/t/trimaran_enc_3des.c`](../../../c/t/trimaran_enc_3des.c) |
| C3 | [`c3/t/trimaran_enc_3des.c3`](../../../c3/t/trimaran_enc_3des.c3) |
| C++ | [`cpp/t/trimaran_enc_3des.cpp`](../../../cpp/t/trimaran_enc_3des.cpp) |
| Elisa | [`elisa/t/trimaran_enc_3des.elisa`](../../../elisa/t/trimaran_enc_3des.elisa) |
| Nim | [`nim/t/trimaran_enc_3des.nim`](../../../nim/t/trimaran_enc_3des.nim) |
| Odin | [`odin/t/trimaran_enc_3des.odin`](../../../odin/t/trimaran_enc_3des.odin) |
| Rust | [`rust/t/trimaran_enc_3des.rs`](../../../rust/t/trimaran_enc_3des.rs) |
| V | [`v/t/trimaran_enc_3des.v`](../../../v/t/trimaran_enc_3des.v) |
| Zig | [`zig/t/trimaran_enc_3des.zig`](../../../zig/t/trimaran_enc_3des.zig) |
