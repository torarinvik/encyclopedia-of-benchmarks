# Shootout Lists benchmark

The pinned launcher compiles `lists.c` with `-lm` and supplies no run options. The source’s `SIZE` is 100. One pass builds a circular doubly linked list of 1 through 100 and a copy, checks equality, drains the copy from its head into a third list, drains that list from its tail back into the copy, reverses the original, and checks both reversed lists and their endpoints. Each pass returns 100. The `main` function repeats the pass for its argument and prints only the last result; zero passes print `0`.

The suite exposes the `i64_scalar_bytes_output` ABI with `shootout_lists(runs, output, output_capacity)`. Its bounded profile accepts 0 through 10,000 runs. The pinned launcher defaults to 3,000,000 (or 300,000 with `SMALL_PROBLEM_SIZE`), so the suite cap keeps calls bounded while preserving each full list pass. The result is `0\n` for zero runs and `100\n` otherwise. Inputs outside the profile return -1. A null or undersized output buffer returns -2 without writing.

[`workload.json`](workload.json) records the launcher, bounds, stdout cases, and buffer errors. [`shootout_lists_oracle.py`](../../shootout_lists_oracle.py) models the node movements independently with Python sequences and verifies the source’s list invariants.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/s/shootout_lists.c](../../../c/s/shootout_lists.c) |
| C3 | [c3/s/shootout_lists.c3](../../../c3/s/shootout_lists.c3) |
| C++ | [cpp/s/shootout_lists.cpp](../../../cpp/s/shootout_lists.cpp) |
| Elisa | [elisa/s/shootout_lists.elisa](../../../elisa/s/shootout_lists.elisa) |
| Nim | [nim/s/shootout_lists.nim](../../../nim/s/shootout_lists.nim) |
| Odin | [odin/s/shootout_lists.odin](../../../odin/s/shootout_lists.odin) |
| Rust | [rust/s/shootout_lists.rs](../../../rust/s/shootout_lists.rs) |
| V | [v/s/shootout_lists.v](../../../v/s/shootout_lists.v) |
| Zig | [zig/s/shootout_lists.zig](../../../zig/s/shootout_lists.zig) |

## Pinned source

- [lists.c at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/lists/lists.c)
- [info.sh at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/lists/info.sh)
