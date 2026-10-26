# cBench LAME analysis window subband filterbank

This package isolates one call to LAME's `window_subband`: it applies the
initialized analysis window to a 511-sample PCM slice, forms the symmetric
intermediate terms, runs the 16-row polyphase cosine mix, and produces all 32
subband values. It does not process a frame, maintain overlap state, run MDCT,
or encode MP3 data. It is separate from the existing long- and short-block
MDCT packages and LAME's stereo mid-side conversion.

## Contract

The exported symbol is `cbench_consumer_lame_window_subband` with the
`i64_array_bytes_output` ABI. The exact input length is 767 signed integers:

- 511 signed 16-bit PCM samples, corresponding to source indices `xk[0..510]`;
- 256 entries from `enwindow[]`, each represented as its source decimal value
  multiplied by 1,000,000,000 and rounded to an integer. This makes the
  source's decimal literals portable in the signed-integer ABI. The source
  coefficient table is present in the valid workload fixture.

The profile checks sample values in `[-32768,32767]`, coefficient values in
`[-4500000,36000000]`, and requires the table's normalization denominators at
indices `0, 8, 24, ..., 248` to exceed 25,000,000. It converts coefficients to
binary64 by division by 1e9, then follows the source order that normalizes
`enwindow`, builds `mmax` and the 16×31 `mm` cosine table, forms the 31
intermediate terms, and computes the 32 bands.

For portable byte output, each binary64 band result is projected to signed
Q1000 by rounding `abs(value*1000)+0.5` toward zero and restoring the sign
(nearest integer, ties away from zero). The 32 signed i64 values are returned
little-endian in band order (256 bytes). Invalid input returns `-1`; a null or
short output returns `-2` without writes. The independent oracle and source
table fixture are included in this package.

## Source and rights

Source: `window_subband` in
[`cBench/consumer_lame/src/newmdct.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/consumer_lame/src/newmdct.c),
pinned at lac-dcc/Benchmarks commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38` (function lines 130–197;
`mdct_init48` table initialization lines 433–543). The source declares
LGPL-2.0-or-later and Takehiro Tominaga's 1999 copyright. The exact applicable
notice is retained in every port; see [`LICENSE.txt`](LICENSE.txt). The source
launcher is [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/consumer_lame/src/info.sh).

The profile externalizes the fixed `enwindow` literals as a bounded input
table so all ports share the same setup values without embedding a separate
copy in each language. The source's recurrence and statement order remain in
the kernel; the workload uses the pinned source table and a zero-sample
hand-derived case. No runtime validation is claimed.

## Ports and oracle

- C: [`c/m/cbench_consumer_lame_window_subband.c`](../../../c/m/cbench_consumer_lame_window_subband.c)
- C3: [`c3/m/cbench_consumer_lame_window_subband.c3`](../../../c3/m/cbench_consumer_lame_window_subband.c3)
- C++: [`cpp/m/cbench_consumer_lame_window_subband.cpp`](../../../cpp/m/cbench_consumer_lame_window_subband.cpp)
- Elisa: [`elisa/m/cbench_consumer_lame_window_subband.elisa`](../../../elisa/m/cbench_consumer_lame_window_subband.elisa)
- Nim: [`nim/m/cbench_consumer_lame_window_subband.nim`](../../../nim/m/cbench_consumer_lame_window_subband.nim)
- Odin: [`odin/m/cbench_consumer_lame_window_subband.odin`](../../../odin/m/cbench_consumer_lame_window_subband.odin)
- Rust: [`rust/m/cbench_consumer_lame_window_subband.rs`](../../../rust/m/cbench_consumer_lame_window_subband.rs)
- V: [`v/m/cbench_consumer_lame_window_subband.v`](../../../v/m/cbench_consumer_lame_window_subband.v)
- Zig: [`zig/m/cbench_consumer_lame_window_subband.zig`](../../../zig/m/cbench_consumer_lame_window_subband.zig)
- Oracle: [`cbench_consumer_lame_window_subband_oracle.py`](../../cbench_consumer_lame_window_subband_oracle.py)
- Workload: [`workload.json`](workload.json)
