# Project Euler Problem 115: Counting block arrangements II

## Contract

`problem115(min_block_length)` returns the least row length `n` for which the number of valid fillings exceeds 1,000,000. Each red block has length at least the input minimum, and adjacent red blocks must have at least one black square between them. The workload supports minimum lengths 1 through 100; other inputs return `-1`. The canonical input 50 returns 168.

The ports preserve the pinned source recurrence. For each candidate row length starting at `m`, initialize the all-black arrangement, then visit each red block length from `m` through `n`. Each possible block start that leaves room for a required separator contributes the count for its remaining prefix; each block length also contributes the arrangement with that block flush against the left edge. The row length is returned as soon as its count is strictly greater than one million.

## Source review

The pinned Python [`sol1`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_115/sol1.py) initializes counts for row lengths below `m` to one. It scans `n` upward from `m`, appends the all-black arrangement, then applies the nested block-length and block-start recurrence. It stops at the first row whose count exceeds (not equals) 1,000,000. The benchmark preserves these update and stopping rules, with input `m` bounded to 1..100 so fixed-size arrays and signed 64-bit counters remain sufficient.

## Workload

[`workload.json`](workload.json) covers the lower bound, source examples `m=3` and `m=10`, canonical `m=50`, supported upper bound, and invalid values.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem115.c](../../../c/p/problem115.c) |
| C3 | [c3/p/problem115.c3](../../../c3/p/problem115.c3) |
| C++ | [cpp/p/problem115.cpp](../../../cpp/p/problem115.cpp) |
| Elisa | [elisa/p/problem115.elisa](../../../elisa/p/problem115.elisa) |
| Nim | [nim/p/problem115.nim](../../../nim/p/problem115.nim) |
| Odin | [odin/p/problem115.odin](../../../odin/p/problem115.odin) |
| Rust | [rust/p/problem115.rs](../../../rust/p/problem115.rs) |
| V | [v/p/problem115.v](../../../v/p/problem115.v) |
| Zig | [zig/p/problem115.zig](../../../zig/p/problem115.zig) |
