# Stanford Bubblesort benchmark

## Contract

The pinned launcher compiles `Bubblesort.c` with `-lm` and runs it without options. Although the source also defines a 5000-element array for Quick, `Bubble` uses `srtelements=500`. Each invocation of `Bubble(run)` resets the seed to 74755 and generates 500 values with `seed = (seed * 1309 + 13849) & 65535`, mapping each to `temp - (temp / 100000) * 100000 - 50000`. It tracks the extrema from zero, as the source does.

Each pass performs the full bubble-sort loop: start `top` at 500, compare each adjacent pair from index 1 through `top-1`, swap only when the left value is greater, then decrement `top`. It does not stop early when a pass makes no swaps. Equal values are left in their input order. After sorting, it checks that the first and last values equal the tracked extrema, prints `Error3 in Bubble.\n` if that check fails, and prints `sortlist[run + 1]` as a decimal line. The launcher calls `Bubble(0)` through `Bubble(99)`.

The suite accepts `runs` from 1 through 100. Every requested pass regenerates and fully sorts the same deterministic 500-value input, then prints the next ascending rank, so a call returns the first `runs` lines of launcher output. The source's endpoint check passes for this fixed input. The maximum output is 700 bytes.

## ABI and workload

The `i64_scalar_bytes_output` entry point is `stanford_bubblesort(runs, output, output_capacity)`, where `runs` is a signed 64-bit scalar. It returns the exact source stdout bytes, -1 for an invalid run count, and -2 for a null or undersized output buffer. Ports stage output before copying it, so error returns leave the buffer untouched.

[workload.json](workload.json) covers one run, two runs, the launcher default, invalid signed bounds, and buffer errors. [stanford_bubblesort_oracle.py](../../stanford_bubblesort_oracle.py) independently generates the values and uses Python's stable sort to derive the same selected output ranks.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/s/stanford_bubblesort.c](../../../c/s/stanford_bubblesort.c) |
| C3 | [c3/s/stanford_bubblesort.c3](../../../c3/s/stanford_bubblesort.c3) |
| C++ | [cpp/s/stanford_bubblesort.cpp](../../../cpp/s/stanford_bubblesort.cpp) |
| Elisa | [elisa/s/stanford_bubblesort.elisa](../../../elisa/s/stanford_bubblesort.elisa) |
| Nim | [nim/s/stanford_bubblesort.nim](../../../nim/s/stanford_bubblesort.nim) |
| Odin | [odin/s/stanford_bubblesort.odin](../../../odin/s/stanford_bubblesort.odin) |
| Rust | [rust/s/stanford_bubblesort.rs](../../../rust/s/stanford_bubblesort.rs) |
| V | [v/s/stanford_bubblesort.v](../../../v/s/stanford_bubblesort.v) |
| Zig | [zig/s/stanford_bubblesort.zig](../../../zig/s/stanford_bubblesort.zig) |

## Pinned source

- [Bubblesort.c at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/Bubblesort/Bubblesort.c)
- [info.sh at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/Bubblesort/info.sh)
