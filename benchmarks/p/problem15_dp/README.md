# Project Euler Problem 15: two-dimensional dynamic programming

## Contract

Return the number of right/down paths across a square lattice of side `grid_size`. The supported range is `0..=20`; out-of-range signed 64-bit inputs return `-1`. A zero-size grid has one route.

This benchmark preserves the distinct O(n²)-time, O(n²)-space table recurrence from the pinned Python `sol2.py`: initialize the table to one, then fill each interior cell as the sum of its upper and left neighbors. The neighboring `problem15` benchmark uses a multiplicative O(n)-time recurrence instead.

## Source and workload

The pinned source is [TheAlgorithms/Python `sol2.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_015/sol2.py) at commit `e1a2a8b016001309a73d5fec4818c35cca139795`. Its default 20×20 result is 137846528820. The bounded domain keeps every path count representable as signed 64-bit and makes the table size fixed for the ports.

[`workload.json`](workload.json) covers the zero, small, midrange, and maximum grids plus invalid bounds.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem15_dp.c](../../../c/p/problem15_dp.c) |
| C3 | [c3/p/problem15_dp.c3](../../../c3/p/problem15_dp.c3) |
| C++ | [cpp/p/problem15_dp.cpp](../../../cpp/p/problem15_dp.cpp) |
| Elisa | [elisa/p/problem15_dp.elisa](../../../elisa/p/problem15_dp.elisa) |
| Nim | [nim/p/problem15_dp.nim](../../../nim/p/problem15_dp.nim) |
| Odin | [odin/p/problem15_dp.odin](../../../odin/p/problem15_dp.odin) |
| Rust | [rust/p/problem15_dp.rs](../../../rust/p/problem15_dp.rs) |
| V | [v/p/problem15_dp.v](../../../v/p/problem15_dp.v) |
| Zig | [zig/p/problem15_dp.zig](../../../zig/p/problem15_dp.zig) |

## Verification

Run `python3 benchmarks/verify_scalar.py --algorithm problem15_dp` to check the ports against the independent exact binomial oracle.
