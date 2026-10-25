# MediaBench G.721 adaptive differential PCM encoder

This package implements the bounded u-law-to-G.721 encoder path selected by
the pinned MediaBench launcher. Its adaptive 2-pole/6-zero predictor,
log-domain difference quantizer, adaptive step scale, transition detector, and
state update are distinct from the local IMA/DVI `lac_adpcm` recurrence, which
uses a single reconstructed-sample predictor and a table-index step size.

## Contract

- ABI: `i64_array_bytes_output`, symbol `mediabench_g721_encode`.
- Input is `[count, u_law_byte...]`, with `count` from 0 through 16 and exactly
  `count` payload values in `0..255`. State resets to the G.721 initial state
  on every call.
- Each input byte follows the launcher's default u-law conversion before the
  14-bit G.721 encoder. The implementation uses the pinned G.721 4-bit code
  tables and adaptive predictor update; A-law, linear PCM, G.723 24/40-kbit
  modes, and decoding are outside this profile.
- Codes are packed in source order, first code in the low nibble and second
  code in the high nibble. An odd final code has a zero high nibble. The result
  is the number of output bytes, `ceil(count / 2)`; maximum output is 8 bytes.
- Invalid input returns `-1`. Null or short output for a nonempty result
  returns `-2` without writing. Empty input returns 0 and accepts a null output.

The Python oracle independently represents the adaptive state and exposes
`expected_output` for bounded inputs and generated verifier cases. Static
fixtures include hand-derived first-sample codewords: u-law `0xff` decodes to
silence and yields G.721 code `0xf`, while `0xf7` decodes to 16 in the encoder's
14-bit domain and yields code `0x6` from the initial state.

## Provenance and rights

Pinned source is `lac-dcc/Benchmarks` at commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. `mediabench/g721/g721encode/info.sh`
selects `encode.c`, `g711.c`, `g721.c`, `g723_24.c`, `g723_40.c`, and `g72x.c`;
the launcher supplies `../data/clinton.pcm` on standard input. The wrapper's
defaults are u-law input and G.721 4-bit output. This package keeps the default
codec path, its state reset, and its least-significant-nibble-first output
packing, while replacing file I/O with an explicit bounded byte vector.

The pinned `g711.c`, `g721.c`, `g72x.c`, and `g72x.h` carry Sun Microsystems'
notice granting unrestricted use, copy, and modification without charge, with
the accompanying warranty and liability disclaimers. The complete notice is
retained in each language port. The launcher adapter `encode.c` has no
separate license notice; its CLI and file wrapper were not copied, and the
bounded adapter was independently written from the pinned defaults and byte
packing behavior. No rights are inferred from unrelated codec copies.

- [`encode.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/mediabench/g721/g721encode/encode.c)
- [`g711.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/mediabench/g721/g721encode/g711.c)
- [`g721.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/mediabench/g721/g721encode/g721.c)
- [`g72x.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/mediabench/g721/g721encode/g72x.c)
- [`g72x.h`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/mediabench/g721/g721encode/g72x.h)
- [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/mediabench/g721/g721encode/info.sh)

## Language ports

| Language | Source |
| --- | --- |
| C | [c/g/mediabench_g721_encode.c](../../../c/g/mediabench_g721_encode.c) |
| C3 | [c3/g/mediabench_g721_encode.c3](../../../c3/g/mediabench_g721_encode.c3) |
| C++ | [cpp/g/mediabench_g721_encode.cpp](../../../cpp/g/mediabench_g721_encode.cpp) |
| Elisa | [elisa/g/mediabench_g721_encode.elisa](../../../elisa/g/mediabench_g721_encode.elisa) |
| Nim | [nim/g/mediabench_g721_encode.nim](../../../nim/g/mediabench_g721_encode.nim) |
| Odin | [odin/g/mediabench_g721_encode.odin](../../../odin/g/mediabench_g721_encode.odin) |
| Rust | [rust/g/mediabench_g721_encode.rs](../../../rust/g/mediabench_g721_encode.rs) |
| V | [v/g/mediabench_g721_encode.v](../../../v/g/mediabench_g721_encode.v) |
| Zig | [zig/g/mediabench_g721_encode.zig](../../../zig/g/mediabench_g721_encode.zig) |

Independent oracle: [`mediabench_g721_encode_oracle.py`](../../mediabench_g721_encode_oracle.py).
