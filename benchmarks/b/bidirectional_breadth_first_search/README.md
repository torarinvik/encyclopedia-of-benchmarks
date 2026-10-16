# Bidirectional breadth-first search

Find a shortest path between two cells in a bounded rectangular grid with blocked cells. This is a two-ended grid-path workload, distinct from graph BFS benchmarks that return vertex visitation order.

## Pinned source

- Python: [TheAlgorithms/Python `bidirectional_breadth_first_search.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/bidirectional_breadth_first_search.py)

The pinned file demonstrates a fixed 7×7 grid. Its two queues do not track discovered cells, and it tests for a meeting only when the two currently popped nodes are equal. The ports make the intended bidirectional shortest-path operation usable for bounded grid inputs: they mark cells when enqueued, expand complete layers alternately from the start and goal, and stop at the first cross-frontier discovery. This also prevents the source loop from cycling on small connected grids.

## Contract

Input is a signed 64-bit array `[rows, columns, start_cell_id, goal_cell_id, blocked_count, blocked_cell_ids...]`. Each dimension is 1 through 8, for at most 64 cells. Cell IDs are zero-based row-major indices. Blocked IDs must be unique, in range, and may not contain either endpoint.

Each side expands one complete FIFO layer, starting with the start side and then the goal side. Neighbors are considered in up, left, down, right order. Search stops when a newly discovered cell has already been discovered by the opposite side. This first intersection has minimum path distance because the two complete BFS layers advance alternately. The meeting cell is emitted only once in the reconstructed path. If the endpoints are disconnected, output is `[0]`.

Output is a little-endian signed 64-bit vector `[path_cell_count, cell_id_0, cell_id_1, ...]`; `path_cell_count` counts cells, including both endpoints. The function returns the number of output bytes written. Invalid input returns `-1`; insufficient or null output capacity returns `-2` without writing. The maximum output is 65 values (520 bytes).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/bidirectional_breadth_first_search.c`](../../../c/b/bidirectional_breadth_first_search.c) |
| C3 | [`c3/b/bidirectional_breadth_first_search.c3`](../../../c3/b/bidirectional_breadth_first_search.c3) |
| C++ | [`cpp/b/bidirectional_breadth_first_search.cpp`](../../../cpp/b/bidirectional_breadth_first_search.cpp) |
| Elisa | [`elisa/b/bidirectional_breadth_first_search.elisa`](../../../elisa/b/bidirectional_breadth_first_search.elisa) |
| Nim | [`nim/b/bidirectional_breadth_first_search.nim`](../../../nim/b/bidirectional_breadth_first_search.nim) |
| Odin | [`odin/b/bidirectional_breadth_first_search.odin`](../../../odin/b/bidirectional_breadth_first_search.odin) |
| Rust | [`rust/b/bidirectional_breadth_first_search.rs`](../../../rust/b/bidirectional_breadth_first_search.rs) |
| V | [`v/b/bidirectional_breadth_first_search.v`](../../../v/b/bidirectional_breadth_first_search.v) |
| Zig | [`zig/b/bidirectional_breadth_first_search.zig`](../../../zig/b/bidirectional_breadth_first_search.zig) |
