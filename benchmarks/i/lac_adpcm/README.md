# LAC-DCC IMA/DVI ADPCM

This package provides one bounded encoder/decoder workload for the IMA/DVI
adaptive differential PCM core in the pinned `telecom_adpcm_c` and
`telecom_adpcm_d` launchers. No local ADPCM codec was present; the existing
Burkes dithering package is an unrelated image-processing algorithm.

## Contract

The `i64_array_bytes_output` interface accepts `[mode, count, payload...]`.
Mode `1` encodes 0–256 signed 16-bit PCM samples. The encoder starts with the
source program's zero-initialized predictor and index, emits the first 4-bit
code in the high nibble, and places a zero in the unused low nibble when the
sample count is odd. It returns `ceil(count / 2)` bytes.

Mode `2` decodes 0–128 packed bytes, consuming the high nibble before the low
nibble as the source decoder does. The result is two signed 16-bit samples per
input byte, serialized as canonical little-endian bytes. The original wrapper
writes native `short` samples; the explicit little-endian representation keeps
this portable contract stable across target hosts. Both modes restart state at
predictor 0 and step index 0 for each call. Invalid input returns `-1`; a null
or undersized output for nonempty results returns `-2` without writing. Zero
count returns zero without needing an output buffer.

The independent Python oracle implements code quantization, predictor clamping,
step-index adaptation, and nibble order separately from the language ports.
Small encoder and decoder traces are in [`workload.json`](workload.json).

## Provenance and license

Pinned sources:

- [`cBench/telecom_adpcm_c/src/adpcm.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/telecom_adpcm_c/src/adpcm.c), using `adpcm_coder`.
- [`cBench/telecom_adpcm_d/src/adpcm.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/telecom_adpcm_d/src/adpcm.c), using `adpcm_decoder`.
- [`mediabench/adpcm/rawcaudio/adpcm.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/mediabench/adpcm/rawcaudio/adpcm.c), using `adpcm_coder`.
- [`mediabench/adpcm/rawdaudio/adpcm.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/mediabench/adpcm/rawdaudio/adpcm.c), using `adpcm_decoder`.

Both are pinned at `lac-dcc/Benchmarks` commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. They identify the coder as the
IMA Compatibility Project's Intel/DVI algorithm, version 1.2 (18 Dec 1992).
Mediabench's rawcaudio and rawdaudio copies share the same pinned `adpcm.c`
Git blob (`c4dfa50350a43d2a961d6397eb03a4df29530d5a`) and implement these same
two recurrences; their file-oriented launchers are aliases, not separate
algorithm packages.
The complete source permission and warranty notice is reproduced here and in
every port:

> Copyright 1992 by Stichting Mathematisch Centrum, Amsterdam, The Netherlands.
>
> All Rights Reserved
>
> Permission to use, copy, modify, and distribute this software and its
> documentation for any purpose and without fee is hereby granted, provided
> that the above copyright notice appear in all copies and that both that
> copyright notice and this permission notice appear in supporting
> documentation, and that the names of Stichting Mathematisch Centrum or CWI
> not be used in advertising or publicity pertaining to distribution of the
> software without specific, written prior permission.
>
> STICHTING MATHEMATISCH CENTRUM DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS
> SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS,
> IN NO EVENT SHALL STICHTING MATHEMATISCH CENTRUM BE LIABLE FOR ANY SPECIAL,
> INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
> LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE
> OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
> PERFORMANCE OF THIS SOFTWARE.

The ports preserve this notice and implement the bounded operations directly.
They omit the dataset reader, repeat-count loop wrapper, and native-endian
stdout handling.

## Language ports

| Language | Source |
| --- | --- |
| C | [c/i/lac_adpcm.c](../../../c/i/lac_adpcm.c) |
| C3 | [c3/i/lac_adpcm.c3](../../../c3/i/lac_adpcm.c3) |
| C++ | [cpp/i/lac_adpcm.cpp](../../../cpp/i/lac_adpcm.cpp) |
| Elisa | [elisa/i/lac_adpcm.elisa](../../../elisa/i/lac_adpcm.elisa) |
| Nim | [nim/i/lac_adpcm.nim](../../../nim/i/lac_adpcm.nim) |
| Odin | [odin/i/lac_adpcm.odin](../../../odin/i/lac_adpcm.odin) |
| Rust | [rust/i/lac_adpcm.rs](../../../rust/i/lac_adpcm.rs) |
| V | [v/i/lac_adpcm.v](../../../v/i/lac_adpcm.v) |
| Zig | [zig/i/lac_adpcm.zig](../../../zig/i/lac_adpcm.zig) |

Independent oracle: [`lac_adpcm_oracle.py`](../../lac_adpcm_oracle.py).
