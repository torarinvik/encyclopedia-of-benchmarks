# Lee breadth-first search

This benchmark ports the pinned Rust Lee algorithm over a rectangular binary matrix. It uses four-neighbor movement in up, left, right, down order, marks cells visited when enqueued, and returns the shortest number of steps.

## Contract

Input is `[rows, cols, source_row, source_col, destination_row, destination_col, row_major_cells...]`, with dimensions 1 through 8 and cell values 0 or 1. Valid coordinates are required. A blocked endpoint or unreachable destination returns -1; malformed data returns -2.

See [workload](workload.json), [independent oracle](../../lee_breadth_first_search_oracle.py), and pinned [Rust source](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/graph/lee_breadth_first_search.rs).

| Language | Port |
|---|---|
| C | [`c/l/lee_breadth_first_search.c`](../../../c/l/lee_breadth_first_search.c) |
| C3 | [`c3/l/lee_breadth_first_search.c3`](../../../c3/l/lee_breadth_first_search.c3) |
| C++ | [`cpp/l/lee_breadth_first_search.cpp`](../../../cpp/l/lee_breadth_first_search.cpp) |
| Elisa | [`elisa/l/lee_breadth_first_search.elisa`](../../../elisa/l/lee_breadth_first_search.elisa) |
| Nim | [`nim/l/lee_breadth_first_search.nim`](../../../nim/l/lee_breadth_first_search.nim) |
| Odin | [`odin/l/lee_breadth_first_search.odin`](../../../odin/l/lee_breadth_first_search.odin) |
| Rust | [`rust/l/lee_breadth_first_search.rs`](../../../rust/l/lee_breadth_first_search.rs) |
| V | [`v/l/lee_breadth_first_search.v`](../../../v/l/lee_breadth_first_search.v) |
| Zig | [`zig/l/lee_breadth_first_search.zig`](../../../zig/l/lee_breadth_first_search.zig) |
