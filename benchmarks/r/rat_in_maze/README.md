# Rat in a Maze

This package preserves the different backtracking contracts in the pinned
Python and Rust implementations as two explicit variants.

## Contract

The input is a signed-i64 array. Its first word selects the variant:

| Variant | Input layout | Cell encoding | Search order and destination |
|---:|---|---|---|
| `0` Python | `[0, n, source_row, source_col, destination_row, destination_col, cells...]` | `0=open`, `1=wall` | Square `n×n`; custom source and destination; down, right, up, left. |
| `1` Rust | `[1, rows, cols, start_row, start_col, cells...]` | `1=open`, `0=blocked` | Rectangular grid; destination is bottom-right; right, down, left, up. |

Rows and columns are in `1..8`. Python requires `n` in `1..8` and exactly
`n*n` cells. Rust requires exactly `rows*cols` cells. Coordinates are
zero-based and must be in range. Each cell must be 0 or 1. Both routines use
depth-first search and return the first path in their source-defined direction
order. Failed branches unmark their route cells, so the search may explore a
cell again on a later branch.

The source result encoding is retained in the output. For variant 0, each
solution-matrix word is 0 for a route cell and 1 for every other cell. For
variant 1, each boolean-matrix word is 1 for a route cell and 0 otherwise. The
words are row-major little-endian signed i64 values; the dimensions are known
from the input, so the output has no header.

The Python routine returns its solution matrix or raises when there is no
route. The Rust routine returns `Some(matrix)` or `None`. The ABI maps these
no-route outcomes to `-3` and writes no bytes. Rust checks its bottom-right
base case before checking whether that cell is open, so a blocked destination
is marked as part of a route whenever the search reaches it; a blocked 1×1
maze also succeeds. Python requires the destination cell to be open.

The largest valid input is 70 words; 71 words are parseable to detect trailing
data. The largest output is 64 words (512 bytes). Invalid framing, dimensions,
coordinates, variant, or cell encoding returns `-1` before output-capacity
checks. A valid route with a null or short output buffer returns `-2` without
writes. A no-route result returns `-3` before output-capacity checks. Success
returns the output byte count.

## Pinned sources

- Python [`rat_in_maze.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/backtracking/rat_in_maze.py), `solve_maze`, commit `e1a2a8b016001309a73d5fec4818c35cca139795`.
- Rust [`rat_in_maze.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/backtracking/rat_in_maze.rs), `find_path_in_maze`, commit `fed66cb0c74c4a939ec5163648458a8c2b46fd4c`.

## Workload and oracle

- Workload: [`workload.json`](workload.json)
- Oracle: [`benchmarks/rat_in_maze_oracle.py`](../../rat_in_maze_oracle.py)

## Language ports

| Language | Port |
|---|---|
| C | [`c/r/rat_in_maze.c`](../../../c/r/rat_in_maze.c) |
| C3 | [`c3/r/rat_in_maze.c3`](../../../c3/r/rat_in_maze.c3) |
| C++ | [`cpp/r/rat_in_maze.cpp`](../../../cpp/r/rat_in_maze.cpp) |
| Elisa | [`elisa/r/rat_in_maze.elisa`](../../../elisa/r/rat_in_maze.elisa) |
| Nim | [`nim/r/rat_in_maze.nim`](../../../nim/r/rat_in_maze.nim) |
| Odin | [`odin/r/rat_in_maze.odin`](../../../odin/r/rat_in_maze.odin) |
| Rust | [`rust/r/rat_in_maze.rs`](../../../rust/r/rat_in_maze.rs) |
| V | [`v/r/rat_in_maze.v`](../../../v/r/rat_in_maze.v) |
| Zig | [`zig/r/rat_in_maze.zig`](../../../zig/r/rat_in_maze.zig) |
