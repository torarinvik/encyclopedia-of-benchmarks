# Minimum Path Sum

## Contract

Given a nonempty rectangular grid of nonnegative integer costs, return the minimum cost of a path from the top-left cell to the bottom-right cell. A move may go one cell right or down. The signed 64-bit input is `[rows, columns, row-major cell costs...]`; each dimension is in `1..=8`, and each cost is in `0..=1000`. Invalid dimensions, length, or costs return `INT64_MIN`.

The ports use a one-row dynamic program. For each cell they add its cost to the smaller of the path totals from above and from the left; the first row and column have only one incoming direction. At most 15 cells contribute to a path, so valid results are at most 15,000 and fit the pinned Java `int` return type.

This package covers only right/down movement from the top-left to the bottom-right. [`minimum_falling_path_sum`](../minimum_falling_path_sum/README.md) allows a different set of moves between rows, while [`minimum_cost_path`](../minimum_cost_path/README.md) is a separate graph-style path problem.

## Workload

[`workload.json`](workload.json) covers both pinned grids, a single cell, one-row and one-column grids, ties, all-zero and maximum-size grids, and malformed dimensions or cell values.

## TheAlgorithms references

- Java [`MinimumPathSum`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/MinimumPathSum.java) uses a one-dimensional DP array and allows only right/down moves.
- Python [`min_path_sum`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/minimum_path_sum.py) accumulates the same recurrence into the grid.
- R [`minimum_path_sum_optimized`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/dynamic_programming/minimum_path_sum.r) computes and returns the same minimum total in its space-optimized variant.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/m/minimum_path_sum.c](../../../c/m/minimum_path_sum.c) |
| C3 | [c3/m/minimum_path_sum.c3](../../../c3/m/minimum_path_sum.c3) |
| C++ | [cpp/m/minimum_path_sum.cpp](../../../cpp/m/minimum_path_sum.cpp) |
| Elisa | [elisa/m/minimum_path_sum.elisa](../../../elisa/m/minimum_path_sum.elisa) |
| Nim | [nim/m/minimum_path_sum.nim](../../../nim/m/minimum_path_sum.nim) |
| Odin | [odin/m/minimum_path_sum.odin](../../../odin/m/minimum_path_sum.odin) |
| Rust | [rust/m/minimum_path_sum.rs](../../../rust/m/minimum_path_sum.rs) |
| V | [v/m/minimum_path_sum.v](../../../v/m/minimum_path_sum.v) |
| Zig | [zig/m/minimum_path_sum.zig](../../../zig/m/minimum_path_sum.zig) |
