# Reed-Solomon (shortened RS(204,188))

This package ports the `rsenc_204`/`rsdec_204` path from [`Misc/ReedSolomon/ReedSolomon.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/ReedSolomon/ReedSolomon.c) at commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The source uses GF(2^8) with primitive polynomial `0x11d`, a 16-symbol generator, and a shortened RS(204,188) frame derived from RS(255,239).

The `misc_reed_solomon` profile takes 188 payload bytes, an error count of 0 or 1, and, for one error, a codeword position and replacement byte. It runs the source encoder, injects the requested replacement, and corrects the resulting codeword. The bounded profile uses at most one altered symbol, within the source decoder's eight-symbol correction capability. The output is the corrected 204-byte codeword: the original 188 payload bytes followed by the 16 parity bytes. Invalid input returns `-1`; a null or short output buffer returns `-2` without writing. See [`workload.json`](workload.json) for all bounds and fixtures.

The upstream launcher invokes a randomized encode/corrupt/decode loop 150,000 times by default (15,000 with `SMALL_PROBLEM_SIZE`) and prints no output. This profile replaces libc randomness with explicit input bytes and bounds the work to one message so every port receives a deterministic contract. It keeps the source's field polynomial, generator construction, shortened-frame layout, and encoding order. The one-error decoder specialization is equivalent to the pinned decoder over this profile's domain.

Verifier source covers replacements that leave symbols unchanged at both ends
of the payload and parity ranges, as well as changed symbols. These checks are
written but have not been run.

Ports are provided in C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, and Zig. The independent Python oracle is [`misc_reed_solomon_oracle.py`](../../misc_reed_solomon_oracle.py). The Mojo draft has not been compiled or run.

For this fixed frame and field size, encoding and the two-syndrome correction
take `O(1)` time and auxiliary space. More generally, the parity update takes
`O(message_symbols × parity_symbols)` field operations.

## Upstream permission

The pinned source permits free modification and redistribution if Simon Rockliff's contribution remains acknowledged in the program comments. The complete original notice is reproduced in [`LICENSE.txt`](LICENSE.txt), and each port identifies Rockliff in its opening comment.

## Port files

| Language | Source |
| --- | --- |
| C | [`c/m/misc_reed_solomon.c`](../../../c/m/misc_reed_solomon.c) |
| C3 | [`c3/m/misc_reed_solomon.c3`](../../../c3/m/misc_reed_solomon.c3) |
| C++ | [`cpp/m/misc_reed_solomon.cpp`](../../../cpp/m/misc_reed_solomon.cpp) |
| Elisa | [`elisa/m/misc_reed_solomon.elisa`](../../../elisa/m/misc_reed_solomon.elisa) |
| Mojo | [`mojo/m/misc_reed_solomon.mojo`](../../../mojo/m/misc_reed_solomon.mojo) (unverified draft) |
| Nim | [`nim/m/misc_reed_solomon.nim`](../../../nim/m/misc_reed_solomon.nim) |
| Odin | [`odin/m/misc_reed_solomon.odin`](../../../odin/m/misc_reed_solomon.odin) |
| Rust | [`rust/m/misc_reed_solomon.rs`](../../../rust/m/misc_reed_solomon.rs) |
| V | [`v/m/misc_reed_solomon.v`](../../../v/m/misc_reed_solomon.v) |
| Zig | [`zig/m/misc_reed_solomon.zig`](../../../zig/m/misc_reed_solomon.zig) |

