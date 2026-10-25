# Trimaran `enc-pc1` (bounded Pukall Cipher 1)

This package ports the distinct Pukall Cipher 1 byte-stream transform from the pinned Trimaran benchmark. It keeps the source's 16-bit state recurrence, 32-byte evolving key, `my_rand_r` LCG stream, and plaintext-feedback ordering. The local repository has no Pukall-PC1 implementation; this algorithm is distinct from its ARC4, Salsa, A5, and block-cipher packages.

## Contract

The `i64_array_scalar` ABI function `trimaran_enc_pc1` accepts exactly one signed 64-bit value: source `NumInput`, in `1..=2049`. The source uses `while (--NumInput)`, so the call processes `NumInput - 1` bytes, at most 2048. It starts with the source's default 32-byte key `abcdefghijklmnopqrstuvwxyz012345`, a zero-initialized 16-word PC1 state, `si = 0`, `x1a2 = 0`, and the source LCG seed 1. For each byte, the transform assembles the key-derived state, XORs every key byte with the plaintext byte, then XORs the input with the two-byte mask derived from `inter`.

Success returns the last source `c` value, in `0..=32767`; for `NumInput=1`, the source loop is empty and the return is zero. Invalid input returns `-1`. The result reconstructs the source's printed `d/e` pair as `16*d + e`. The workload's source-reference case uses `NumInput=2049`, which processes 2048 bytes; the pinned small reference begins that print interval with `1384 14`, giving `22158`.

## Provenance and rights

- Launcher: [Trimaran/enc-pc1/info.sh](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Trimaran/enc-pc1/info.sh) at commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. It selects the single `pc1cod.c` source and passes 1,000,000 in small mode or 20,000,000 by default.
- Algorithm source: [Trimaran/enc-pc1/pc1cod.c](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Trimaran/enc-pc1/pc1cod.c), same commit. Its header identifies Alexander Pukall (1991), states “free code no restriction to use,” and asks that his name be included in final software. Each local port and this README preserve that attribution. The ports are independently written from the published source behavior rather than copied source text.
- The expected source output pair is visible at the beginning of the pinned [small reference output](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Trimaran/enc-pc1/enc-pc1.reference_output.small).

The bounded profile changes the launcher input count to cap work at the first 2048-byte output interval. It omits the banner, file I/O, and formatted stream output; the scalar live-out is the last `c` value that the source splits into `d` and `e`.

## Files

| Language | Port |
| --- | --- |
| C | [`c/t/trimaran_enc_pc1.c`](../../../c/t/trimaran_enc_pc1.c) |
| C3 | [`c3/t/trimaran_enc_pc1.c3`](../../../c3/t/trimaran_enc_pc1.c3) |
| C++ | [`cpp/t/trimaran_enc_pc1.cpp`](../../../cpp/t/trimaran_enc_pc1.cpp) |
| Elisa | [`elisa/t/trimaran_enc_pc1.elisa`](../../../elisa/t/trimaran_enc_pc1.elisa) |
| Nim | [`nim/t/trimaran_enc_pc1.nim`](../../../nim/t/trimaran_enc_pc1.nim) |
| Odin | [`odin/t/trimaran_enc_pc1.odin`](../../../odin/t/trimaran_enc_pc1.odin) |
| Rust | [`rust/t/trimaran_enc_pc1.rs`](../../../rust/t/trimaran_enc_pc1.rs) |
| V | [`v/t/trimaran_enc_pc1.v`](../../../v/t/trimaran_enc_pc1.v) |
| Zig | [`zig/t/trimaran_enc_pc1.zig`](../../../zig/t/trimaran_enc_pc1.zig) |

The independent oracle is [`trimaran_enc_pc1_oracle.py`](../../trimaran_enc_pc1_oracle.py), and the bounded fixtures are in [`workload.json`](workload.json).
