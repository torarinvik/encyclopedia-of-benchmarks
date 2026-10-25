# MiBench LAME long-block MDCT

This package isolates LAME's 18-sample long-block MDCT kernel from the MiBench
`consumer-lame` launcher. It accepts the already windowed 18-value vector that
`mdct_long` consumes and returns its 18 transform coefficients. It omits the
polyphase analysis filterbank, overlap/window construction, short-block path,
alias-reduction butterfly, MP3 bitstream, WAV I/O, and launcher timing loop.

## Contract

The exported symbol is `mibench_lame_mdct_long` with the `float64_slice_io`
ABI. Input is exactly 18 finite binary64 samples, each in `[-16,16]`. Output
is 18 binary64 coefficients in source bin order, compared with absolute and
relative tolerances `1e-10`.

For `m=0..17`, the independently expressed transform is
`out[m] = (4/36) * sum(x[k] * cos(pi*(2*m+1)*q[k]/144), k=0..17)`, where
`q[k]=4*k+38` for `k<9` and `q[k]=4*k+74` otherwise. This is the linear
transform represented by the factorized `mdct_long` and its precomputed
`cos_l` table: the table uses the first nine values from its `N` block and
the next nine from its `3N` block. The factor is `4/N` for the source's
`N=36` long transform. Inputs here are the post-window values passed to that helper;
the caller's windowing and previous/current granule assembly are not implied.

Malformed length, nonfinite values, or values outside the declared range
return `-1` before output-capacity checks. A null output or capacity below 18
returns `-2`. Success writes all 18 values and returns 18. Errors do not write
the output.

## Source and rights

Pinned source: `lac-dcc/Benchmarks` commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`,
[`MiBench/consumer-lame/newmdct.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/consumer-lame/newmdct.c),
symbols `mdct_long` and `mdct_sub48`; launcher
[`MiBench/consumer-lame/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/consumer-lame/info.sh)
selects the LAME encoder on `large.wav`.

`newmdct.c` credits Takehiro Tominaga and declares GNU Library General Public
License version 2 or later. The pinned LAME `LICENSE` notice and the LGPL
license terms are retained in this package. These ports are clean-room
implementations of the documented mathematical transform and do not copy
LAME source or its tables. Preserve the notice and LGPL terms with this
source-backed profile.

The independent model is [`mibench_lame_mdct_long_oracle.py`](../../mibench_lame_mdct_long_oracle.py);
the bounded fixtures are in [`workload.json`](workload.json).

## Ports

- C: [`c/m/mibench_lame_mdct_long.c`](../../../c/m/mibench_lame_mdct_long.c)
- C3: [`c3/m/mibench_lame_mdct_long.c3`](../../../c3/m/mibench_lame_mdct_long.c3)
- C++: [`cpp/m/mibench_lame_mdct_long.cpp`](../../../cpp/m/mibench_lame_mdct_long.cpp)
- Elisa: [`elisa/m/mibench_lame_mdct_long.elisa`](../../../elisa/m/mibench_lame_mdct_long.elisa)
- Nim: [`nim/m/mibench_lame_mdct_long.nim`](../../../nim/m/mibench_lame_mdct_long.nim)
- Odin: [`odin/m/mibench_lame_mdct_long.odin`](../../../odin/m/mibench_lame_mdct_long.odin)
- Rust: [`rust/m/mibench_lame_mdct_long.rs`](../../../rust/m/mibench_lame_mdct_long.rs)
- V: [`v/m/mibench_lame_mdct_long.v`](../../../v/m/mibench_lame_mdct_long.v)
- Zig: [`zig/m/mibench_lame_mdct_long.zig`](../../../zig/m/mibench_lame_mdct_long.zig)

No runtime, compiler, or validator verification is claimed.
