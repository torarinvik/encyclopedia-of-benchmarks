# Project Euler Problem 136: Singleton difference

## Contract

`problem136(n_limit)` counts positive integers `n < n_limit` with exactly one representation as `x²-y²-z²`, where `x`, `y`, and `z` are positive consecutive terms of an arithmetic progression. The workload supports limits from 0 through 100,000; negative inputs preserve the source’s empty-range result 0, and values above 100,000 return `-1`. The source examples include `3 → 0`, `10 → 3`, `100 → 25`, and `110 → 27`.

The source substitution gives `n = y * (4*delta - y)` with `delta < y < 4*delta`. The ports traverse `delta` and `y` in the same order, stop the inner loop when `n >= n_limit`, and count representations per n. Counts saturate at two because only the distinction between exactly one and multiple representations affects the returned result.

## Source review

The pinned Python [`sol1`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_136/sol1.py) allocates one count per `n_limit`, sets the maximum `delta` from `(n_limit + 1) // 4`, scans `y` downward from `4*delta-1` to just above `delta`, breaks once the generated n reaches the exclusive limit, then counts entries equal to one. The benchmark preserves those bounds and stopping order within a 100,000 limit so the fixed count table remains bounded.

## Workload

[`workload.json`](workload.json) covers source examples, empty and negative inputs, a medium limit, the supported upper bound, and the first out-of-range value.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem136.c](../../../c/p/problem136.c) |
| C3 | [c3/p/problem136.c3](../../../c3/p/problem136.c3) |
| C++ | [cpp/p/problem136.cpp](../../../cpp/p/problem136.cpp) |
| Elisa | [elisa/p/problem136.elisa](../../../elisa/p/problem136.elisa) |
| Nim | [nim/p/problem136.nim](../../../nim/p/problem136.nim) |
| Odin | [odin/p/problem136.odin](../../../odin/p/problem136.odin) |
| Rust | [rust/p/problem136.rs](../../../rust/p/problem136.rs) |
| V | [v/p/problem136.v](../../../v/p/problem136.v) |
| Zig | [zig/p/problem136.zig](../../../zig/p/problem136.zig) |
