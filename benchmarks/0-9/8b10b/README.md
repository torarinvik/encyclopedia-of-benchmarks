# VersaBench 8b10b

The pinned launcher calls the direct, table-driven `calc` implementation: `info.sh` does not define `BIG_CALC`. For an input array of `N` packed words, `testbench.c` runs the full array `N` times without resetting running disparity, overwrites the result array on every pass, then prints the final pass values at indices `0, 128, 256, ...` with `printf("%8.8X\n")`. The pinned launcher uses 2,000 words with `SMALL_PROBLEM_SIZE` and 20,000 otherwise.

The suite exposes `versabench_8b10b(values, length, output, capacity)` through the `i64_array_bytes_output` ABI. Each input value is the source word `(k << 8) | byte`, with `byte` in 0..255 and `k` in 0..1. Length `N` is bounded to 0..160, so the adapter executes at most 25,600 table lookups while retaining the source's N passes, continuous disparity state, final-pass sampling, and exact uppercase eight-digit ASCII lines. The profile returns 0 and no bytes for an empty array; a null input pointer at length zero has the same result. A null input pointer with positive length, invalid lengths, or invalid packed words return -1; a null output or insufficient capacity for a nonempty result returns -2 without writing.

The pinned input file contains little-endian unsigned 32-bit words in 0..511. The workload examples use its prefix and also cover empty input, the 128-element output-sampling boundary, maximum bounded length, and error paths. The independent oracle models the table selections and disparity transitions separately from the language ports. The source includes an MIT license notice; these ports implement the bounded contract independently.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/0-9/8b10b.c](../../../c/0-9/8b10b.c) |
| C3 | [c3/0-9/8b10b.c3](../../../c3/0-9/8b10b.c3) |
| C++ | [cpp/0-9/8b10b.cpp](../../../cpp/0-9/8b10b.cpp) |
| Elisa | [elisa/0-9/8b10b.elisa](../../../elisa/0-9/8b10b.elisa) |
| Nim | [nim/0-9/8b10b.nim](../../../nim/0-9/8b10b.nim) |
| Odin | [odin/0-9/8b10b.odin](../../../odin/0-9/8b10b.odin) |
| Rust | [rust/0-9/8b10b.rs](../../../rust/0-9/8b10b.rs) |
| V | [v/0-9/8b10b.v](../../../v/0-9/8b10b.v) |
| Zig | [zig/0-9/8b10b.zig](../../../zig/0-9/8b10b.zig) |

## Pinned source

- [calc.c at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/VersaBench/8b10b/calc.c)
- [testbench.c at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/VersaBench/8b10b/testbench.c)
- [info.sh at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/VersaBench/8b10b/info.sh)
- [workload.json](workload.json)
- [independent oracle](../../versabench_8b10b_oracle.py)
