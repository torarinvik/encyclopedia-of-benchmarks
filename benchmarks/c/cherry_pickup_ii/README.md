# Cherry Pickup II

Maximize the total value collected by two robots moving together through a
bounded grid. They start at the upper-left and upper-right cells, move down
exactly one row at a time with a column change of at most one, and both must
reach the bottom row. A cell's value is collected only once if both robots
occupy it on the same row.

## Contract

The exported scalar ABI symbol is `cherry_pickup_ii`. Input is
`[rows,columns,grid row-major]`, with both dimensions in `2..6`, each cell in
`0..100`, and exact length `2+rows*columns`. A maximum valid input has 38 words;
the 39-word parser bound allows one trailing-word malformed-frame probe. Null,
malformed, or out-of-domain input returns `-1`.

Valid results are in `0..1200`. Since cells are nonnegative, an overlap adds
that cell's value once and there is always a legal move to the next row.

## Algorithms

The primary keeps a rolling table indexed by the two robot columns. A state
contains the best score after both robots reach the current row. Each transition
tries the nine pairs of legal column shifts; the row's cell values are added
once when the columns coincide. It takes `O(rows*columns^2*9)` time and
`O(columns^2)` auxiliary space.

The independent reference recursively enumerates every pair of legal robot
paths and scores each complete pair directly, without dynamic programming. Its
work is bounded by `O(9^(rows-1))` paired movement sequences.

## Distinctness and provenance

The nearby `minimum_path_sum`, `minimum_falling_path_sum`, and
`minimum_path_cost_in_grid` packages optimize one path; `unique_paths`
counts paths. They do not track two synchronized positions or deduplicate
reward when both paths share a cell. This package uses the problem and movement rules from the official
[LeetCode 1463 description](https://leetcode.com/problems/cherry-pickup-ii/);
the implementation is clean-room and the workload is original.

See [`RIGHTS.md`](RIGHTS.md), [`workload.json`](workload.json), both oracle
modules, and [`check_inventory.py`](check_inventory.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/c/cherry_pickup_ii.c`](../../../c/c/cherry_pickup_ii.c) |
| C3 | [`c3/c/cherry_pickup_ii.c3`](../../../c3/c/cherry_pickup_ii.c3) |
| C++ | [`cpp/c/cherry_pickup_ii.cpp`](../../../cpp/c/cherry_pickup_ii.cpp) |
| Elisa | [`elisa/c/cherry_pickup_ii.elisa`](../../../elisa/c/cherry_pickup_ii.elisa) |
| Mojo | [`mojo/c/cherry_pickup_ii.mojo`](../../../mojo/c/cherry_pickup_ii.mojo) |
| Nim | [`nim/c/cherry_pickup_ii.nim`](../../../nim/c/cherry_pickup_ii.nim) |
| Odin | [`odin/c/cherry_pickup_ii.odin`](../../../odin/c/cherry_pickup_ii.odin) |
| Rust | [`rust/c/cherry_pickup_ii.rs`](../../../rust/c/cherry_pickup_ii.rs) |
| V | [`v/c/cherry_pickup_ii.v`](../../../v/c/cherry_pickup_ii.v) |
| Zig | [`zig/c/cherry_pickup_ii.zig`](../../../zig/c/cherry_pickup_ii.zig) |
