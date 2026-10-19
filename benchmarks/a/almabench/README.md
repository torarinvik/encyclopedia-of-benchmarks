# CoyoteBench almabench

## Contract

The pinned launcher compiles `almabench.c` with `-lm` and runs it without options. The source calculates daily positions for Mercury through Neptune using the Simon–Bretagnon orbital-element model, rotates each position into the J2000 equatorial frame, and prints right ascension, declination, and distance for each planet. The default profile computes 36525 days and repeats that pass 20 times; `SMALL_PROBLEM_SIZE` selects 3652 days and one pass. Both passes reset the date and produce identical final output.

This suite accepts `days` in 1..36525. It performs one pass, calculates all eight planets for each date from J2000+1 through J2000+days, and returns the final day’s eight output lines. `days=36525` reproduces the launcher’s default final date. Each line follows the source format `RA DEC DIST` with six digits after each decimal point and LF.

## ABI and workload

The `i64_scalar_bytes_output` entry point is `almabench(days, output, output_capacity)`. It returns the complete ASCII output length, -1 for an invalid day count, and -2 for a null or undersized output buffer. Ports stage output before copying it. The maximum output is 248 bytes.

[workload.json](workload.json) includes the first two dates, the `SMALL_PROBLEM_SIZE` day bound, the launcher default, signed-boundary invalid values, and output-buffer errors. [almabench_oracle.py](../../almabench_oracle.py) independently computes the requested final Julian date and all eight planet positions; each language port retains the daily loop so the bounded workload performs the source’s full sequence of ephemeris calculations.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/a/almabench.c](../../../c/a/almabench.c) |
| C3 | [c3/a/almabench.c3](../../../c3/a/almabench.c3) |
| C++ | [cpp/a/almabench.cpp](../../../cpp/a/almabench.cpp) |
| Elisa | [elisa/a/almabench.elisa](../../../elisa/a/almabench.elisa) |
| Nim | [nim/a/almabench.nim](../../../nim/a/almabench.nim) |
| Odin | [odin/a/almabench.odin](../../../odin/a/almabench.odin) |
| Rust | [rust/a/almabench.rs](../../../rust/a/almabench.rs) |
| V | [v/a/almabench.v](../../../v/a/almabench.v) |
| Zig | [zig/a/almabench.zig](../../../zig/a/almabench.zig) |

## Pinned source

- [almabench.c at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/CoyoteBench/almabench/almabench.c)
- [info.sh at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/CoyoteBench/almabench/info.sh)
