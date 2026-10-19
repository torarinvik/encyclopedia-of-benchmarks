# Trimaran ARC4 benchmark

This profile covers the pinned `Trimaran/enc-rc4/rc4.c` implementation by Christophe Devine at LAC-DCC/Benchmarks commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. Its state setup and byte-generation loop follow `rc4_setup` and `rc4_crypt`. The benchmark launcher runs six fixed validation vectors for 2,000 repetitions in small mode and 1,000,000 repetitions otherwise.

The bounded `trimaran_enc_rc4` call takes one signed integer: `passes`, from 1 through 2,000. For each of the six source vectors in order, it restores the vector's input and repeats setup plus encryption `passes` times. The function returns 82 ciphertext bytes concatenated in vector order. This exposes the kernel results while retaining the small-mode repetition bound. Invalid input returns `-1`; a null or short output buffer returns `-2` without writes.

This profile is distinct from the generic [`rc4`](../../r/rc4/README.md) package: it preserves the six fixed Trimaran inputs, their ordering, reset behavior, and bounded repetition loop. See [`workload.json`](workload.json) and the independent [`oracle`](../../trimaran_enc_rc4_oracle.py).

The source grants use under the GNU General Public License, version 2 or (at the recipient's option) any later version. That grant expressly permits modification and redistribution subject to the license. The original notice is in [`LICENSE_NOTICE.txt`](LICENSE_NOTICE.txt), and the complete GPL text is in [`LICENSE-GPL-2.0-or-later.txt`](LICENSE-GPL-2.0-or-later.txt).

| Language | Port |
|---|---|
| C | [`trimaran_enc_rc4.c`](../../../c/t/trimaran_enc_rc4.c) |
| C3 | [`trimaran_enc_rc4.c3`](../../../c3/t/trimaran_enc_rc4.c3) |
| C++ | [`trimaran_enc_rc4.cpp`](../../../cpp/t/trimaran_enc_rc4.cpp) |
| Elisa | [`trimaran_enc_rc4.elisa`](../../../elisa/t/trimaran_enc_rc4.elisa) |
| Nim | [`trimaran_enc_rc4.nim`](../../../nim/t/trimaran_enc_rc4.nim) |
| Odin | [`trimaran_enc_rc4.odin`](../../../odin/t/trimaran_enc_rc4.odin) |
| Rust | [`trimaran_enc_rc4.rs`](../../../rust/t/trimaran_enc_rc4.rs) |
| V | [`trimaran_enc_rc4.v`](../../../v/t/trimaran_enc_rc4.v) |
| Zig | [`trimaran_enc_rc4.zig`](../../../zig/t/trimaran_enc_rc4.zig) |
