# Project Euler Problem 18: Maximum path sum I

## Contract

Given a triangle in row-major order, return the maximum sum along a path from the top to the bottom, moving to either adjacent entry on each next row. Input is `[row_count, value_0, ..., value_(n(n+1)/2-1)]`. Row count is 1..15, the input must contain exactly `row_count * (row_count + 1) / 2` values after the header, and each value is in `0..=1,000,000`. Invalid input returns `-1`.

The ports copy the values into a fixed-size buffer and fold the triangle upward. At each parent, they add the larger of its two child totals. This takes O(n²) time and O(n²) space, with n bounded by 15 rows.

## Workload

[`workload.json`](workload.json) covers a single row, a two-row choice, the four-row example from the problem statement, the canonical 15-row triangle, and malformed input.

## TheAlgorithms reference

- Julia [`problem_018`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/project_euler/problem_018.jl) implements the same fixed 15-row triangle with dynamic programming and returns 1074.
- Go [`Problem18`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/project_euler/problem_18/problem18.go) builds a complete binary tree from strings and searches root-descendant paths to a requested depth. It is a distinct tree-path routine, not an implementation of the Project Euler triangle recurrence.
- The canonical triangle and the four-row example follow the [Project Euler Problem 18 statement](https://projecteuler.net/problem%3D018).

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem18.c](../../../c/p/problem18.c) |
| C3 | [c3/p/problem18.c3](../../../c3/p/problem18.c3) |
| C++ | [cpp/p/problem18.cpp](../../../cpp/p/problem18.cpp) |
| Elisa | [elisa/p/problem18.elisa](../../../elisa/p/problem18.elisa) |
| Nim | [nim/p/problem18.nim](../../../nim/p/problem18.nim) |
| Odin | [odin/p/problem18.odin](../../../odin/p/problem18.odin) |
| Rust | [rust/p/problem18.rs](../../../rust/p/problem18.rs) |
| V | [v/p/problem18.v](../../../v/p/problem18.v) |
| Zig | [zig/p/problem18.zig](../../../zig/p/problem18.zig) |
