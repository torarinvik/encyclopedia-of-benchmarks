# MiBench fixed-point integer square root

This package ports the `usqrt` digit-by-digit binary square-root routine from
MiBench automotive-basicmath. It returns a 16-bit-fraction fixed-point root,
`floor(sqrt(x) * 65536)`, as the source's `q.sqrt` field.

## Contract

- ABI: `i64_array_scalar`, symbol `mibench_automotive_basicmath_isqrt`.
- Input is one unsigned value in `[0, 65535]`. This bounded range is contained
  in the source's ascending integer workload and keeps the source's 32-bit
  intermediate arithmetic in range.
- The algorithm consumes 32 two-bit groups, shifts the partial root, tests
  `(2 * root + 1)` against the partial remainder, then subtracts and sets the
  next root bit when the trial fits.
- The result is `floor(sqrt(input) * 2^16)`. Invalid framing or values return
  `-1`.

The independent [oracle](../../mibench_automotive_basicmath_isqrt_oracle.py)
replays the 32-bit recurrence. The workload covers perfect and non-perfect
roots, zero, the upper bounded value, and invalid framing and values.

## Provenance and license

The pinned launcher builds `basicmath.c`, `cubic.c`, `isqrt.c`, and `rad2deg.c`
with `-lm` and takes no arguments. The `isqrt.c` and launcher files do not
state a redistribution license; this package records no inferred license and
uses independent ports of the described recurrence.

- [Pinned `isqrt.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/automotive-basicmath/isqrt.c)
- [Pinned `basicmath.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/automotive-basicmath/basicmath.c)
- [Pinned launcher](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/automotive-basicmath/info.sh)

## Language ports

| Language | Source |
| --- | --- |
| C | [c/m/mibench_automotive_basicmath_isqrt.c](../../../c/m/mibench_automotive_basicmath_isqrt.c) |
| C3 | [c3/m/mibench_automotive_basicmath_isqrt.c3](../../../c3/m/mibench_automotive_basicmath_isqrt.c3) |
| C++ | [cpp/m/mibench_automotive_basicmath_isqrt.cpp](../../../cpp/m/mibench_automotive_basicmath_isqrt.cpp) |
| Elisa | [elisa/m/mibench_automotive_basicmath_isqrt.elisa](../../../elisa/m/mibench_automotive_basicmath_isqrt.elisa) |
| Nim | [nim/m/mibench_automotive_basicmath_isqrt.nim](../../../nim/m/mibench_automotive_basicmath_isqrt.nim) |
| Odin | [odin/m/mibench_automotive_basicmath_isqrt.odin](../../../odin/m/mibench_automotive_basicmath_isqrt.odin) |
| Rust | [rust/m/mibench_automotive_basicmath_isqrt.rs](../../../rust/m/mibench_automotive_basicmath_isqrt.rs) |
| V | [v/m/mibench_automotive_basicmath_isqrt.v](../../../v/m/mibench_automotive_basicmath_isqrt.v) |
| Zig | [zig/m/mibench_automotive_basicmath_isqrt.zig](../../../zig/m/mibench_automotive_basicmath_isqrt.zig) |
