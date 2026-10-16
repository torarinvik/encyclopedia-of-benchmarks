# Project Euler Problem 173: square laminae

## Contract

For a tile limit from 0 through 1,000,000, return the number of distinct square outlines with a square hole that can be formed using at most that many tiles. Limits outside the benchmark domain return `-1`.

The ports preserve the pinned outer-width scan from 3 up to (but not including) `limit // 4 + 2`. For each outer square, the minimum hole width is at least 1 and, when the outer area exceeds the tile limit, at least `ceil(sqrt(outer_width² - limit))`. The hole width is then increased by one when needed to match the outer width's parity. The source formula counts the allowable hole widths in steps of two. An exact integer ceiling-square-root helper implements the same mathematical boundary as the source's `ceil(sqrt(...))` over this bounded domain.

The problem statement's illustration says exactly 32 tiles can form two laminae. The `solution(limit)` function counts all laminae using up to the limit, so `solution(32)` returns 9 and `solution(100)` returns 41. The source default of 1,000,000 returns **1,572,729**.

## Workload

[`workload.json`](workload.json) covers the smallest thresholds, cumulative limits 32 and 100, the canonical default, and invalid limits.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_173/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem173.c](../../../c/p/problem173.c) |
| C3 | [c3/p/problem173.c3](../../../c3/p/problem173.c3) |
| C++ | [cpp/p/problem173.cpp](../../../cpp/p/problem173.cpp) |
| Elisa | [elisa/p/problem173.elisa](../../../elisa/p/problem173.elisa) |
| Nim | [nim/p/problem173.nim](../../../nim/p/problem173.nim) |
| Odin | [odin/p/problem173.odin](../../../odin/p/problem173.odin) |
| Rust | [rust/p/problem173.rs](../../../rust/p/problem173.rs) |
| V | [v/p/problem173.v](../../../v/p/problem173.v) |
| Zig | [zig/p/problem173.zig](../../../zig/p/problem173.zig) |
