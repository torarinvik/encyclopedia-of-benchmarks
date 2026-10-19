# Stanford Towers benchmark

## Contract

The pinned launcher compiles `Towers.c` with `-lm` and runs it without options. Its `main` calls `Towers()` 100 times. Each pass initializes the source's 18-cell free-list pool, places 14 disks on peg 1, and recursively transfers them to peg 2 using peg 3 as the auxiliary. The source checks that the move count is 16,383 and prints that count followed by LF. The error diagnostic is absent for this valid run.

The suite accepts `runs` from 1 through 100. Each requested run performs a fresh source-style pool setup and Hanoi transfer, returning one `16383\n` line. A value of 100 reproduces the launcher's 100-line output. The maximum valid output is 600 bytes.

## ABI and workload

The `i64_scalar_bytes_output` entry point is `stanford_towers(runs, output, output_capacity)`. It returns the exact ASCII bytes, -1 for a run count outside 1..100, and -2 for a null or undersized output buffer. Ports stage output before copying it.

[`workload.json`](workload.json) records the pinned launcher, the one-run and launcher-default outputs, range boundaries, and output-buffer errors. [`stanford_towers_oracle.py`](../../stanford_towers_oracle.py) independently simulates legal Hanoi moves with ordinary Python stacks.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/s/stanford_towers.c](../../../c/s/stanford_towers.c) |
| C3 | [c3/s/stanford_towers.c3](../../../c3/s/stanford_towers.c3) |
| C++ | [cpp/s/stanford_towers.cpp](../../../cpp/s/stanford_towers.cpp) |
| Elisa | [elisa/s/stanford_towers.elisa](../../../elisa/s/stanford_towers.elisa) |
| Nim | [nim/s/stanford_towers.nim](../../../nim/s/stanford_towers.nim) |
| Odin | [odin/s/stanford_towers.odin](../../../odin/s/stanford_towers.odin) |
| Rust | [rust/s/stanford_towers.rs](../../../rust/s/stanford_towers.rs) |
| V | [v/s/stanford_towers.v](../../../v/s/stanford_towers.v) |
| Zig | [zig/s/stanford_towers.zig](../../../zig/s/stanford_towers.zig) |

## Pinned source

- [Towers.c at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/Towers/Towers.c)
- [info.sh at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/Towers/info.sh)
