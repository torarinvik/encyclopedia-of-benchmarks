# LAME stereo mid-side conversion

This package isolates the per-coefficient `ms_convert` operation in LAME's `convert_mdct` branch. The upstream helper transforms each left/right spectral pair into normalized mid and side values. It is distinct from LAME's long-block MDCT package: this kernel runs after the spectral values exist and changes the two-channel representation. The pinned launcher supplies no mode option, so this standalone contract covers the conditional helper rather than claiming every default launcher invocation reaches it.

## Contract

ABI: `float64_slice_io`; exported symbol: `cbench_lame_mid_side`.

Input is `[n, L0..L(n-1), R0..R(n-1)]`, where `1 <= n <= 32` and every sample is finite binary64 in `[-16,16]`. Output is interleaved `[M0,S0,M1,S1,...]`, with `M=(L+R)*(sqrt(2)*0.5)` and `S=(L-R)*(sqrt(2)*0.5)`. The multiplication order follows the source helper. The factor is computed once as binary64 `sqrt(2)*0.5`. Output length is `2*n`; the input and output maxima are 65 words and 64 binary64 elements. Malformed input returns `-1`; null or short output returns `-2`. All output is staged so error results leave the caller's buffer unchanged.

The profile models the source's channel transform only. Granule assembly, mode signaling, psychoacoustic decisions, MDCT, quantization, Huffman coding, and bitstream writing are excluded.

## Provenance and rights

- Repository and pin: [`lac-dcc/Benchmarks@5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38).
- Launcher: [`cBench/consumer_lame/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/consumer_lame/src/info.sh).
- Source: [`cBench/consumer_lame/src/quantize-pvt.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/consumer_lame/src/quantize-pvt.c), helper `ms_convert` (lines 298–308). Its caller is in [`quantize.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/consumer_lame/src/quantize.c) and is selected when `convert_mdct` is enabled.
- The pinned `quantize.c` source declares GPL-2.0-or-later, copyright Mark Taylor (1999); that source-specific notice is retained in [`LICENSE.txt`](LICENSE.txt). This is distinct from the sibling `newmdct.c` file's LGPL notice. Ports independently implement the stated arithmetic and do not copy upstream code.

The independent oracle is [`cbench_lame_mid_side_oracle.py`](../../cbench_lame_mid_side_oracle.py); fixtures are in [`workload.json`](workload.json). No runtime, compiler, or validator verification is claimed.

## Ports

- C: [`c/m/cbench_lame_mid_side.c`](../../../c/m/cbench_lame_mid_side.c)
- C3: [`c3/m/cbench_lame_mid_side.c3`](../../../c3/m/cbench_lame_mid_side.c3)
- C++: [`cpp/m/cbench_lame_mid_side.cpp`](../../../cpp/m/cbench_lame_mid_side.cpp)
- Elisa: [`elisa/m/cbench_lame_mid_side.elisa`](../../../elisa/m/cbench_lame_mid_side.elisa)
- Nim: [`nim/m/cbench_lame_mid_side.nim`](../../../nim/m/cbench_lame_mid_side.nim)
- Odin: [`odin/m/cbench_lame_mid_side.odin`](../../../odin/m/cbench_lame_mid_side.odin)
- Rust: [`rust/m/cbench_lame_mid_side.rs`](../../../rust/m/cbench_lame_mid_side.rs)
- V: [`v/m/cbench_lame_mid_side.v`](../../../v/m/cbench_lame_mid_side.v)
- Zig: [`zig/m/cbench_lame_mid_side.zig`](../../../zig/m/cbench_lame_mid_side.zig)
