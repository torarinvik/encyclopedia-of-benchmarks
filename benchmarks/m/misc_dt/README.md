# lac-dcc `dt`

This package covers the repeated elementwise binary64 division kernel from the
pinned lac-dcc `Misc/dt` benchmark. It preserves the source's float32
`cosf`/`sinf` initialization, repeated division, and outer-iteration then
inner-index traversal. The bounded contract returns the full final numerator
vector so every division remains observable to the ABI caller; the original
program prints only its first element.

## Contract

The ABI is `float64_slice_io`, symbol `misc_dt`. Input is exactly
`[iteration_count, vector_size]`, with an integer iteration count in 1–128 and
vector size in 1–64. For each index `i`, initialize
`dvec1[i] = 1.0000001 * cosf((float)(vector_size-i))` and
`dvec2[i] = 1.0 + 1e-10 * sinf((float)i)`. The source's loop order is retained:
repeat the full vector pass for each iteration, dividing `dvec1[i]` by
`dvec2[i]` in ascending index order. The result is the final `dvec1` vector.
Malformed input returns `-1`; null output or insufficient capacity returns
`-2` without writing. Comparison tolerance is absolute `1e-6` and relative
`1e-12` to allow platform differences in single-precision trigonometric
functions.

The bounded profile is smaller than the source's fixed 131,072 iterations and
2,048-element vectors. See [`workload.json`](workload.json) and the independent
[`misc_dt_oracle`](../../misc_dt_oracle.py).

## Pinned source

- [`dt.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/dt/dt.c)
- [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/dt/info.sh)

The source has no explicit license grant; the ports are independently written
and no license is inferred.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/m/misc_dt.c](../../../c/m/misc_dt.c) |
| C3 | [c3/m/misc_dt.c3](../../../c3/m/misc_dt.c3) |
| C++ | [cpp/m/misc_dt.cpp](../../../cpp/m/misc_dt.cpp) |
| Elisa | [elisa/m/misc_dt.elisa](../../../elisa/m/misc_dt.elisa) |
| Nim | [nim/m/misc_dt.nim](../../../nim/m/misc_dt.nim) |
| Odin | [odin/m/misc_dt.odin](../../../odin/m/misc_dt.odin) |
| Rust | [rust/m/misc_dt.rs](../../../rust/m/misc_dt.rs) |
| V | [v/m/misc_dt.v](../../../v/m/misc_dt.v) |
| Zig | [zig/m/misc_dt.zig](../../../zig/m/misc_dt.zig) |
