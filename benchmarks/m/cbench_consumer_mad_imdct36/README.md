# cBench consumer_mad IMDCT36

This package isolates libmad's Layer III long-block inverse modified discrete
cosine transform helper, `imdct36`, from the cBench `consumer_mad` launcher.
The bounded operation consumes 18 spectral coefficients and produces the 36
unwindowed time-domain samples. It does not decode MPEG frames, parse side
information or Huffman data, apply block windows, overlap-add synthesis
history, perform polyphase synthesis, or read audio files.

## Contract

The exported symbol is `cbench_consumer_mad_imdct36` with the `float64_slice_io`
ABI. Input is exactly 18 finite binary64 coefficients in `[-16,16]`; output is
36 binary64 samples. For `n=0..35`, ports evaluate the canonical IMDCT

`x[n] = sum(k=0..17, X[k] * cos(pi * (2*n+19) * (2*k+1) / 72))`

in ascending `k` order, with a left-to-right binary64 sum and no normalization
factor. The expression is the mathematical transform implemented by libmad's
factored `imdct36`; the benchmark profile specifies binary64 arithmetic and
does not claim bit-for-bit identity with the launcher's default `FPM_DEFAULT`
Q28 fixed-point multiply-accumulate path. The standard profile uses the
unwindowed helper output before the caller's normal/start/stop block window.

Malformed length, nonfinite inputs, or values outside the bound return `-1`
before output-capacity checks. A null output or capacity below 36 returns
`-2`. Errors leave output untouched. Success writes all 36 samples and returns
36. Comparison tolerances are `1e-11` absolute and relative.

The default fixture is a bounded deterministic coefficient vector, not an
encoded MP3 frame. It exercises the same standalone transform selected by the
source's default build (`FPM_DEFAULT`) while keeping bitstream parsing and
decoder state outside this portable profile.

## Source and rights

Pinned source: `lac-dcc/Benchmarks` commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`,
[`cBench/consumer_mad/src/layer3.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/consumer_mad/src/layer3.c),
symbol `imdct36`; launcher
[`cBench/consumer_mad/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/consumer_mad/src/info.sh)
builds all C sources with `-DFPM_DEFAULT` and no run options. `layer3.c`
credits Robert Leslie and declares GNU GPL version 2 or (at the user's
option) any later version. The complete GPL-2.0 text and source attribution
are retained in [`LICENSE.txt`](LICENSE.txt). These ports independently
implement the mathematical transform and do not copy the libmad factorization
or source tables.

The independent model is
[`cbench_consumer_mad_imdct36_oracle.py`](../../cbench_consumer_mad_imdct36_oracle.py);
fixtures are in [`workload.json`](workload.json).

## Ports

- C: [`c/m/cbench_consumer_mad_imdct36.c`](../../../c/m/cbench_consumer_mad_imdct36.c)
- C3: [`c3/m/cbench_consumer_mad_imdct36.c3`](../../../c3/m/cbench_consumer_mad_imdct36.c3)
- C++: [`cpp/m/cbench_consumer_mad_imdct36.cpp`](../../../cpp/m/cbench_consumer_mad_imdct36.cpp)
- Elisa: [`elisa/m/cbench_consumer_mad_imdct36.elisa`](../../../elisa/m/cbench_consumer_mad_imdct36.elisa)
- Nim: [`nim/m/cbench_consumer_mad_imdct36.nim`](../../../nim/m/cbench_consumer_mad_imdct36.nim)
- Odin: [`odin/m/cbench_consumer_mad_imdct36.odin`](../../../odin/m/cbench_consumer_mad_imdct36.odin)
- Rust: [`rust/m/cbench_consumer_mad_imdct36.rs`](../../../rust/m/cbench_consumer_mad_imdct36.rs)
- V: [`v/m/cbench_consumer_mad_imdct36.v`](../../../v/m/cbench_consumer_mad_imdct36.v)
- Zig: [`zig/m/cbench_consumer_mad_imdct36.zig`](../../../zig/m/cbench_consumer_mad_imdct36.zig)

No runtime, compiler, or validator verification is claimed.
