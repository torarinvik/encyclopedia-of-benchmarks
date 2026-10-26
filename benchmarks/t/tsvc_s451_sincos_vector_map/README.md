# TSVC s451 binary64 sine/cosine vector map

This clean-room profile implements TSVC `s451` for the double-precision
GlobalDataFlow launcher. For each ascending index it emits
`sin(B[i]) + cos(C[i])` using binary64 math functions. It profiles one pass;
the repeated timing loop and dummy call are excluded. The float launcher uses
`sinf`/`cosf` and is not claimed by this binary64-only contract.

This pointwise transcendental map is distinct from s452's index-weighted
arithmetic map and the repository's scalar trigonometry/angle utilities.

## Contract

The exported symbol is `tsvc_s451_sincos_vector_map` using `float64_slice_io`.

- Input is `[n, B[n], C[n]]`, with `1 <= n <= 64` and each angle in
  `[-10,10]` radians.
- Compute `sin(B[i]) + cos(C[i])` in ascending order and emit n binary64
  results. Input is unchanged.
- Invalid framing, nonfinite values, or out-of-range angles return `-1`.
  Null output or capacity below n returns `-2` after validation without
  writes. Comparison tolerance is absolute and relative `1e-14` to allow
  platform libm rounding differences.

## Source and rights

Source: `s451` at lines 4724–4751 of
[`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L4724),
pinned LAC-DCC `Benchmarks` commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The selected double launcher is
[`TSVC/GlobalDataFlow-dbl/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/GlobalDataFlow-dbl/info.sh).
The TSVC source has no explicit redistribution grant in the reviewed
materials. No upstream code or comments are copied; see [LICENSE.txt](LICENSE.txt).

Cases live in [workload.json](workload.json), and the independent oracle is
[`tsvc_s451_sincos_vector_map_oracle.py`](../../tsvc_s451_sincos_vector_map_oracle.py).

## Ports

| Language | Port |
|---|---|
| C | [tsvc_s451_sincos_vector_map.c](../../../c/t/tsvc_s451_sincos_vector_map.c) |
| C3 | [tsvc_s451_sincos_vector_map.c3](../../../c3/t/tsvc_s451_sincos_vector_map.c3) |
| C++ | [tsvc_s451_sincos_vector_map.cpp](../../../cpp/t/tsvc_s451_sincos_vector_map.cpp) |
| Elisa | [tsvc_s451_sincos_vector_map.elisa](../../../elisa/t/tsvc_s451_sincos_vector_map.elisa) |
| Nim | [tsvc_s451_sincos_vector_map.nim](../../../nim/t/tsvc_s451_sincos_vector_map.nim) |
| Odin | [tsvc_s451_sincos_vector_map.odin](../../../odin/t/tsvc_s451_sincos_vector_map.odin) |
| Rust | [tsvc_s451_sincos_vector_map.rs](../../../rust/t/tsvc_s451_sincos_vector_map.rs) |
| V | [tsvc_s451_sincos_vector_map.v](../../../v/t/tsvc_s451_sincos_vector_map.v) |
| Zig | [tsvc_s451_sincos_vector_map.zig](../../../zig/t/tsvc_s451_sincos_vector_map.zig) |
