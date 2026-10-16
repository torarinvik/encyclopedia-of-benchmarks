# Project Euler Problem 15

## Contract

Return the number of routes from the top-left to bottom-right corner of a square `grid_size × grid_size` lattice, using only right and down moves. `grid_size` is in `0..=20`; values outside that range return `-1`. The zero-size grid has one route.

The result is the central binomial coefficient `C(2n, n)`. The ports use a multiplicative recurrence in O(grid_size) time and O(1) extra space, avoiding factorial intermediates. The pinned Go source uses the same identity through factorials, but its machine-integer factorial intermediates overflow at the canonical 20×20 input before the division; the ports keep each intermediate within signed 64-bit range.

## Workload

[`workload.json`](workload.json) covers zero-, one-, two-, and three-cell grids, a ten-cell grid, the canonical 20×20 grid, and invalid bounds.

## TheAlgorithms reference

- Go [`Problem15`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/project_euler/problem_15/problem15.go) computes `(2n)!/(n!)²` for a supplied grid size.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem15.c](../../../c/p/problem15.c) |
| C3 | [c3/p/problem15.c3](../../../c3/p/problem15.c3) |
| C++ | [cpp/p/problem15.cpp](../../../cpp/p/problem15.cpp) |
| Elisa | [elisa/p/problem15.elisa](../../../elisa/p/problem15.elisa) |
| Nim | [nim/p/problem15.nim](../../../nim/p/problem15.nim) |
| Odin | [odin/p/problem15.odin](../../../odin/p/problem15.odin) |
| Rust | [rust/p/problem15.rs](../../../rust/p/problem15.rs) |
| V | [v/p/problem15.v](../../../v/p/problem15.v) |
| Zig | [zig/p/problem15.zig](../../../zig/p/problem15.zig) |
