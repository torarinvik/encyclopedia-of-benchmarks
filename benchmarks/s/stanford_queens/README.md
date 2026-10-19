# Stanford Queens benchmark

## Contract

The pinned launcher compiles `Queens.c` with `-lm` and runs it without options. `main` calls `Queens(run)` for `run = 0..99`. Each pass calls `Doit()` 50 times and then prints `run + 1` as a decimal line.

`Doit` initializes the 8-column and two diagonal-availability arrays, then calls `Try` at row 1. `Try` visits candidate columns in ascending order from 1 to 8, marks a column and both diagonals while descending, and restores them when a recursive branch fails. It stops at the first 8-queens solution. The source prints ` Error in Queens.\n` only if a search fails; the fixed 8-queens problem is solvable, so the launcher emits only pass numbers.

The bounded profile accepts `runs` from 1 through 100 and performs 50 complete eight-queens searches per requested pass before printing that pass's ordinal. The full launcher output is the decimal lines 1 through 100, totaling 292 bytes.

## ABI and workload

The `i64_scalar_bytes_output` entry point is `stanford_queens(runs, output, output_capacity)`. It returns exact source stdout bytes, -1 for an invalid run count, and -2 for a null or undersized output buffer. Ports stage output before copying it, so errors leave the output buffer untouched.

[workload.json](workload.json) covers one pass, two passes, the launcher default, invalid signed bounds, and buffer errors. [stanford_queens_oracle.py](../../stanford_queens_oracle.py) checks solvability with a separate bit-mask search and formats the expected stdout prefix.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/s/stanford_queens.c](../../../c/s/stanford_queens.c) |
| C3 | [c3/s/stanford_queens.c3](../../../c3/s/stanford_queens.c3) |
| C++ | [cpp/s/stanford_queens.cpp](../../../cpp/s/stanford_queens.cpp) |
| Elisa | [elisa/s/stanford_queens.elisa](../../../elisa/s/stanford_queens.elisa) |
| Nim | [nim/s/stanford_queens.nim](../../../nim/s/stanford_queens.nim) |
| Odin | [odin/s/stanford_queens.odin](../../../odin/s/stanford_queens.odin) |
| Rust | [rust/s/stanford_queens.rs](../../../rust/s/stanford_queens.rs) |
| V | [v/s/stanford_queens.v](../../../v/s/stanford_queens.v) |
| Zig | [zig/s/stanford_queens.zig](../../../zig/s/stanford_queens.zig) |

## Pinned source

- [Queens.c at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/Queens/Queens.c)
- [info.sh at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/Queens/info.sh)
