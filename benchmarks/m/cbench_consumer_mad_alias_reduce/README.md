# cBench consumer_mad Layer III alias reduction

This package isolates libmad's eight-pair Layer III frequency-line alias
reduction stage, `III_aliasreduce`. It processes one to four adjacent
18-line subband boundaries. It does not decode an MPEG frame, perform
requantization or stereo processing, run the IMDCT, apply windows, synthesize
PCM, or handle files and command-line options. The local IMDCT package covers
a separate decoder stage.

## Contract

The exported symbol is `cbench_consumer_mad_alias_reduce` with the
`i64_array_bytes_output` ABI. Input is
`[boundary_count, a0,b0,...,a7,b7, ...]`, with 1 to 4 boundaries and exactly
16 signed Q28 `mad_fixed_t` values for each boundary. Each value is bounded to
`[-100000000,100000000]`. For pair `i` at each boundary, the source order is

```
left'  = mad_f_mul(a, cs[i]) + mad_f_mul(-b, ca[i])
right' = mad_f_mul(b, cs[i]) + mad_f_mul(a, ca[i])
```

The constants are the pinned MPEG-1 alias-reduction coefficients from
`layer3.c`. The launcher selects `FPM_DEFAULT`, so this profile specifies its
default pre-rounded multiply (without `OPT_SPEED`):

```
mad_f_mul(x,y) = floor((x + 2^11) / 2^12) * floor((y + 2^15) / 2^16)
```

This explicit floor-division rule matches arithmetic right shifts on the
usual two's-complement targets, including negative operands. The bounded
profile avoids signed multiply/add overflow. Results are emitted as signed
32-bit little-endian Q28 values in boundary order, with each pair's left then
right result. Output length and successful return value are `64 *
boundary_count` bytes, at most 256. Invalid input returns `-1`; null output or
insufficient capacity returns `-2`. Every error leaves output untouched.

The zero fixture and a single 4096-unit impulse have hand-derived results.
The independent oracle models the fixed-point arithmetic directly rather
than using libmad source code. `workload.json` defines malformed-length,
out-of-range, null-input, null-output, and short-capacity cases as well.

## Source and rights

Pinned source: `lac-dcc/Benchmarks` commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`,
[`cBench/consumer_mad/src/layer3.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/consumer_mad/src/layer3.c),
symbol `III_aliasreduce` (source lines 1450–1485); its coefficient table is
at lines 334–355. The exact multiplication macros are in
[`fixed.h`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/consumer_mad/src/fixed.h),
and the launcher
[`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/consumer_mad/src/info.sh)
sets `-DFPM_DEFAULT` without runtime options. The pinned source credits
Robert Leslie, copyright 2000–2001, and declares GNU GPL version 2 or (at
your option) any later version. The complete GPL-2.0 text and attribution are
retained in [`LICENSE.txt`](LICENSE.txt). These language ports are independent
implementations of the documented bounded arithmetic profile.

The independent oracle is
[`cbench_consumer_mad_alias_reduce_oracle.py`](../../cbench_consumer_mad_alias_reduce_oracle.py).

## Ports

- C: [`c/m/cbench_consumer_mad_alias_reduce.c`](../../../c/m/cbench_consumer_mad_alias_reduce.c)
- C3: [`c3/m/cbench_consumer_mad_alias_reduce.c3`](../../../c3/m/cbench_consumer_mad_alias_reduce.c3)
- C++: [`cpp/m/cbench_consumer_mad_alias_reduce.cpp`](../../../cpp/m/cbench_consumer_mad_alias_reduce.cpp)
- Elisa: [`elisa/m/cbench_consumer_mad_alias_reduce.elisa`](../../../elisa/m/cbench_consumer_mad_alias_reduce.elisa)
- Nim: [`nim/m/cbench_consumer_mad_alias_reduce.nim`](../../../nim/m/cbench_consumer_mad_alias_reduce.nim)
- Odin: [`odin/m/cbench_consumer_mad_alias_reduce.odin`](../../../odin/m/cbench_consumer_mad_alias_reduce.odin)
- Rust: [`rust/m/cbench_consumer_mad_alias_reduce.rs`](../../../rust/m/cbench_consumer_mad_alias_reduce.rs)
- V: [`v/m/cbench_consumer_mad_alias_reduce.v`](../../../v/m/cbench_consumer_mad_alias_reduce.v)
- Zig: [`zig/m/cbench_consumer_mad_alias_reduce.zig`](../../../zig/m/cbench_consumer_mad_alias_reduce.zig)

No runtime, compiler, or validator verification is claimed.
