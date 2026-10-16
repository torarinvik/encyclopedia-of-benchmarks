# Project Euler Problem 76

## Contract

For a total from 1 through 200, return the number of partitions into at least two positive parts. The one-part partition containing the total itself is excluded. Inputs outside that range return `-1`.

The ports preserve the pinned source's tabulation: an `(m+1) × m` memo table, first-column values initialized to one, rows visited from zero through `m`, and part columns visited from one through `m-1`. Each cell adds the preceding column and, when `n > k`, the value at row `n-k-1` in the same column. The source then subtracts one from `memo[m][m-1]` to remove the single-part representation.

The documented outputs are `1 -> 0`, `2 -> 1`, `3 -> 2`, `5 -> 6`, `10 -> 41`, `30 -> 5603`, `50 -> 204225`, and `100 -> 190569291`. The additional limit 200 remains within signed 64-bit output and returns 3,972,999,029,387.

Each language exports `int64_t problem76(int64_t total)`.

## Workload

[`workload.json`](workload.json) covers the source examples, the default total, the bounded maximum, and invalid totals.

## TheAlgorithms reference

Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_076/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem76.c](../../../c/p/problem76.c) |
| C3 | [c3/p/problem76.c3](../../../c3/p/problem76.c3) |
| C++ | [cpp/p/problem76.cpp](../../../cpp/p/problem76.cpp) |
| Elisa | [elisa/p/problem76.elisa](../../../elisa/p/problem76.elisa) |
| Nim | [nim/p/problem76.nim](../../../nim/p/problem76.nim) |
| Odin | [odin/p/problem76.odin](../../../odin/p/problem76.odin) |
| Rust | [rust/p/problem76.rs](../../../rust/p/problem76.rs) |
| V | [v/p/problem76.v](../../../v/p/problem76.v) |
| Zig | [zig/p/problem76.zig](../../../zig/p/problem76.zig) |
