# MiBench automotive-basicmath cubic solver

This package ports the SolveCubic routine from the pinned MiBench
automotive-basicmath source. The upstream launcher compiles basicmath.c,
cubic.c, isqrt.c, and rad2deg.c. This package isolates the source's cubic
solver and does not represent the integer square-root and angle-conversion
sections of that combined launcher.

## Contract

The exported function is mibench_automotive_basicmath_cubic and uses the
float64_slice_io ABI. Input is exactly four finite binary64 values in
[a, b, c, d] order for the polynomial ax^3 + bx^2 + cx + d. Coefficients
must have absolute value at most 100, and the leading coefficient must have
absolute value at least 1. Repeated-root cases are outside this bounded profile.
The result contains the real roots in the order produced by the upstream
solver: one real root, or for three real roots, smallest, largest, middle.
Success returns the number of output elements (one or three). Invalid input
returns -1. A null output or capacity below the required count returns -2
without writing.

The independent oracle isolates roots by splitting the real line at the
derivative's critical points and bisecting sign-changing intervals. This
checks the source formula against a different numerical method. The workload
includes source-driver examples, one-root and three-root cubics, a negative
leading coefficient, malformed input, and short output capacity.

## Pinned source and license

- [info.sh](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/automotive-basicmath/info.sh) selects the four source files and no runtime arguments.
- [cubic.c](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/automotive-basicmath/cubic.c) defines SolveCubic and identifies it as public domain by Ross Cottrell.
- [basicmath.c](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/automotive-basicmath/basicmath.c) contains the launcher program's calls and representative coefficients.
- [LICENSE.txt](LICENSE.txt) retains the complete grant statement and attribution present in cubic.c.

## Ports

| Language | Source |
| --- | --- |
| C | [c/m/mibench_automotive_basicmath_cubic.c](../../../c/m/mibench_automotive_basicmath_cubic.c) |
| C3 | [c3/m/mibench_automotive_basicmath_cubic.c3](../../../c3/m/mibench_automotive_basicmath_cubic.c3) |
| C++ | [cpp/m/mibench_automotive_basicmath_cubic.cpp](../../../cpp/mibench_automotive_basicmath_cubic.cpp) |
| Elisa | [elisa/m/mibench_automotive_basicmath_cubic.elisa](../../../elisa/m/mibench_automotive_basicmath_cubic.elisa) |
| Nim | [nim/m/mibench_automotive_basicmath_cubic.nim](../../../nim/m/mibench_automotive_basicmath_cubic.nim) |
| Odin | [odin/m/mibench_automotive_basicmath_cubic.odin](../../../odin/m/mibench_automotive_basicmath_cubic.odin) |
| Rust | [rust/m/mibench_automotive_basicmath_cubic.rs](../../../rust/m/mibench_automotive_basicmath_cubic.rs) |
| V | [v/m/mibench_automotive_basicmath_cubic.v](../../../v/m/mibench_automotive_basicmath_cubic.v) |
| Zig | [zig/m/mibench_automotive_basicmath_cubic.zig](../../../zig/m/mibench_automotive_basicmath_cubic.zig) |

Workload fixtures and measurement bounds are in [workload.json](workload.json).
