# cBench consumer_lame short-block MDCT

This package isolates `newmdct.c::mdct_short`, LAME's three-window short-block
MDCT stage. It consumes the already-formed 18-value work vector and writes
three 6-coefficient transforms side by side into 18 outputs. It excludes PCM
window-subband analysis, construction of the 18 short-block work values,
block selection, alias reduction, bitstream coding, audio files, and the full
encoder.

## Contract

The exported symbol is `cbench_consumer_lame_mdct_short` with the
`float64_slice_io` ABI. Input is exactly 18 finite binary64 values in
`[-32768,32768]`; output is 18 binary64 coefficients. The three input windows
are consecutive groups of six. For `m=0..5` and `l=0..2`, output index
`3*m+l` is the source-ordered sum of six products from input group `l`.

The cosine table is generated from the pinned `mdct_init48` formulas. In
particular, `max = enwindow[248] = 0.030526638`, `SCALE=32768`, and `NS=12`.
For `i=0..2`, the source first computes
`w2 = cos(pi/12*(i+0.5))*max/SCALE*(4/NS)`, then fills coefficients for
`i` and `i+3` with cosine angles using offsets `4*i+14` and `4*i+38`.
This stateless profile recomputes the small source coefficient table per call;
the original launcher initializes it once before processing audio. Products
and six-term sums use binary64 in source order. Malformed input returns `-1`;
null output or capacity below 18 returns `-2`; all errors leave output
untouched. Successful calls write and return 18 values. Comparison tolerance
is `1e-10` absolute and relative.

This is the short-window sibling of the existing 18-sample long-block MDCT,
with a distinct 6-point basis, three interleaved window outputs, and short
window coefficient scaling. It does not claim to encode a short-block MP3
frame.

## Source and rights

Pinned source: `lac-dcc/Benchmarks` commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`,
[`cBench/consumer_lame/src/newmdct.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/consumer_lame/src/newmdct.c),
`mdct_short` at lines 213–235 and its coefficient initialization in
`mdct_init48` at lines 578–590. Launcher:
[`cBench/consumer_lame/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/consumer_lame/src/info.sh).
The source credits Takehiro Tominaga, copyright 1999, and declares GNU LGPL
version 2 or later. Its complete source notice is retained in
[`LICENSE.txt`](LICENSE.txt). The independent ports do not copy the source
table or source text.

The independent model is
[`cbench_consumer_lame_mdct_short_oracle.py`](../../cbench_consumer_lame_mdct_short_oracle.py);
fixtures are in [`workload.json`](workload.json).

## Ports

- C: [`c/m/cbench_consumer_lame_mdct_short.c`](../../../c/m/cbench_consumer_lame_mdct_short.c)
- C3: [`c3/m/cbench_consumer_lame_mdct_short.c3`](../../../c3/m/cbench_consumer_lame_mdct_short.c3)
- C++: [`cpp/m/cbench_consumer_lame_mdct_short.cpp`](../../../cpp/m/cbench_consumer_lame_mdct_short.cpp)
- Elisa: [`elisa/m/cbench_consumer_lame_mdct_short.elisa`](../../../elisa/m/cbench_consumer_lame_mdct_short.elisa)
- Nim: [`nim/m/cbench_consumer_lame_mdct_short.nim`](../../../nim/m/cbench_consumer_lame_mdct_short.nim)
- Odin: [`odin/m/cbench_consumer_lame_mdct_short.odin`](../../../odin/m/cbench_consumer_lame_mdct_short.odin)
- Rust: [`rust/m/cbench_consumer_lame_mdct_short.rs`](../../../rust/m/cbench_consumer_lame_mdct_short.rs)
- V: [`v/m/cbench_consumer_lame_mdct_short.v`](../../../v/m/cbench_consumer_lame_mdct_short.v)
- Zig: [`zig/m/cbench_consumer_lame_mdct_short.zig`](../../../zig/m/cbench_consumer_lame_mdct_short.zig)

No runtime, compiler, or validator verification is claimed.
