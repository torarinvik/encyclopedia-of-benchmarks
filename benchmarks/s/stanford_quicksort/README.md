# Stanford Quicksort

This package ports the pinned Stanford Quicksort benchmark. It regenerates the same 5,000 signed values from the 16-bit linear congruential generator, sorts them with the source's midpoint-pivot partition, and emits the first `prefix_count` sorted values as decimal lines. Every printed rank performs a fresh generation and sort, matching the source `Quick(run)` loop. A prefix count of 100 reproduces the launcher workload.

The `i64_scalar_bytes_output` entry point accepts `prefix_count` from 1 through 100. It returns the exact output prefix, returns -1 outside that range, and returns -2 for a null or undersized output buffer without writing. The maximum output is 700 bytes.

[`workload.json`](workload.json) records pinned source and launcher details, the default 100-line output, range boundaries, and buffer errors. [`stanford_quicksort_oracle.py`](../../stanford_quicksort_oracle.py) uses Python's built-in sort as an independent ordering oracle; the language ports keep the source's recursive quicksort.

| Language | Port |
|---|---|
| C | [c/q/stanford_quicksort.c](../../../c/q/stanford_quicksort.c) |
| C3 | [c3/q/stanford_quicksort.c3](../../../c3/q/stanford_quicksort.c3) |
| C++ | [cpp/q/stanford_quicksort.cpp](../../../cpp/q/stanford_quicksort.cpp) |
| Elisa | [elisa/q/stanford_quicksort.elisa](../../../elisa/q/stanford_quicksort.elisa) |
| Nim | [nim/q/stanford_quicksort.nim](../../../nim/q/stanford_quicksort.nim) |
| Odin | [odin/q/stanford_quicksort.odin](../../../odin/q/stanford_quicksort.odin) |
| Rust | [rust/q/stanford_quicksort.rs](../../../rust/q/stanford_quicksort.rs) |
| V | [v/q/stanford_quicksort.v](../../../v/q/stanford_quicksort.v) |
| Zig | [zig/q/stanford_quicksort.zig](../../../zig/q/stanford_quicksort.zig) |

## Pinned source

- [Quicksort.c at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/Quicksort/Quicksort.c)
- [info.sh at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/Quicksort/info.sh)
