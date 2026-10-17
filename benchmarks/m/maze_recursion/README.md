# Recursive maze solver

This benchmark follows the two recursive search strategies in the pinned Java
`MazeRecursion` implementation. Both start at row 1, column 1 and search for
row 6, column 5, marking successful path cells with `2` and explored dead ends
with `3`.

## Contract

- ABI: `i64_array_bytes_output`.
- Input is exactly 57 signed-i64 words: `[strategy, cell(0,0), ..., cell(7,6)]`.
  Cells are row-major in an 8-by-7 grid, at flat index `1 + 7 * row + column`.
  Strategy `0` tries down, right, up, then left. Strategy `1` tries up, right,
  down, then left.
- Every cell must be `0` (open) or `1` (wall). The full outer ring must be
  walls, and the fixed start `(1,1)` and target `(6,5)` must be open. This keeps
  recursive calls in bounds and excludes source marker values from the input.
  The largest possible open interior contains 30 cells.
- Output is exactly 57 little-endian signed-i32 words: `[found, mutated_grid...]`.
  `found` is 1 when a route is found and 0 otherwise. The map is serialized
  after the search in both cases, so a no-path result retains all mutations
  made while exploring. The Java wrapper returns `null` on no path, but it
  leaves those mutations in the supplied map.
- A null input pointer or invalid input returns `-1` before output-buffer
  checks. A null output pointer or capacity below 228 bytes returns `-2`
  without writing. Every valid call returns 228 bytes.
- Maximum output and workspace are 228 bytes. The independent oracle is
  [`maze_recursion_oracle.py`](../../maze_recursion_oracle.py).

The workload includes both strategy orders, routes, dead ends, disconnected
open regions, malformed grids and strategies, and null, exact, and short output
capacities.

## Pinned source

[TheAlgorithms/Java `MazeRecursion.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/backtracking/MazeRecursion.java)
at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.

## Language ports

| Language | Port |
| --- | --- |
| C | [c/m/maze_recursion.c](../../../c/m/maze_recursion.c) |
| C3 | [c3/m/maze_recursion.c3](../../../c3/m/maze_recursion.c3) |
| C++ | [cpp/m/maze_recursion.cpp](../../../cpp/m/maze_recursion.cpp) |
| Elisa | [elisa/m/maze_recursion.elisa](../../../elisa/m/maze_recursion.elisa) |
| Nim | [nim/m/maze_recursion.nim](../../../nim/m/maze_recursion.nim) |
| Odin | [odin/m/maze_recursion.odin](../../../odin/m/maze_recursion.odin) |
| Rust | [rust/m/maze_recursion.rs](../../../rust/m/maze_recursion.rs) |
| V | [v/m/maze_recursion.v](../../../v/m/maze_recursion.v) |
| Zig | [zig/m/maze_recursion.zig](../../../zig/m/maze_recursion.zig) |
