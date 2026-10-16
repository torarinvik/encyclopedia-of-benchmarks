# Bidirectional A*

This package searches a rectangular grid with four-way movement. Input is a row-major grid where `0` is traversable and `1` is blocked. Coordinates use `[row, column]`, matching the pinned Python source.

The bounded input is `[rows, columns, start_row, start_column, goal_row, goal_column, cells...]`. Each dimension is 1 through 20, so the grid contains at most 400 cells. The input must contain exactly one cell value per coordinate. Endpoints must be in range and traversable. Malformed inputs return `-1`.

Output is `[path_length, row0, column0, row1, column1, ...]` encoded as little-endian signed 64-bit values. A successful path is shortest and includes both endpoints; when no route exists, the output path contains only the start coordinate, as a benchmark-defined fallback. A null or undersized output buffer returns `-2`; success returns the output byte length.

For deterministic ties, the ports use the pinned source's four-neighbor order (up, left, down, right), expand the forward side before the backward side, prioritize by path cost plus floored Euclidean distance, and preserve discovery order when priorities tie. The package tracks visited cells by coordinate and uses a shortest-path lower bound for termination so the returned path remains shortest.

## Source normalization

This is a source-inspired corrected contract, not an exact path-output port. The pinned Python routine mutates each search side's target while existing open nodes retain priorities computed from earlier targets; its `Node` membership uses object identity, so the same coordinate can be enqueued repeatedly. On some disconnected grids with cycles, that source can continue indefinitely. These ports instead keep each goal fixed, track visited coordinates, and terminate using a shortest-path lower bound. The integer floored Euclidean heuristic and coordinate-based state can change tie selection and the returned path while preserving shortest distance. The `[start]` result is defined here for every valid unreachable grid; the source only reaches its fallback on some terminating cases.

| Language | Port |
|---|---|
| C | [`c/b/bidirectional_a_star.c`](../../../c/b/bidirectional_a_star.c) |
| C3 | [`c3/b/bidirectional_a_star.c3`](../../../c3/b/bidirectional_a_star.c3) |
| C++ | [`cpp/b/bidirectional_a_star.cpp`](../../../cpp/b/bidirectional_a_star.cpp) |
| Elisa | [`elisa/b/bidirectional_a_star.elisa`](../../../elisa/b/bidirectional_a_star.elisa) |
| Nim | [`nim/b/bidirectional_a_star.nim`](../../../nim/b/bidirectional_a_star.nim) |
| Odin | [`odin/b/bidirectional_a_star.odin`](../../../odin/b/bidirectional_a_star.odin) |
| Rust | [`rust/b/bidirectional_a_star.rs`](../../../rust/b/bidirectional_a_star.rs) |
| V | [`v/b/bidirectional_a_star.v`](../../../v/b/bidirectional_a_star.v) |
| Zig | [`zig/b/bidirectional_a_star.zig`](../../../zig/b/bidirectional_a_star.zig) |

Pinned source: [TheAlgorithms/Python `bidirectional_a_star.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/bidirectional_a_star.py). The module's example grid, command-line wrapper, and timing code are excluded; its grid representation, coordinate convention, four-way neighbor order, Euclidean heuristic, and no-path fallback inform this contract. See [`workload.json`](workload.json) for representative cases.
