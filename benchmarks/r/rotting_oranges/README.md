# Rotting oranges

This benchmark ports the pinned Java multi-source breadth-first search for
the Rotting Oranges problem. It copies the grid, then spreads rot through
orthogonally adjacent fresh oranges one minute per step. The original grid is
not modified.

## Contract

- ABI: i64_array_scalar. A nonempty rectangular grid is packed as
  [rows, cols, row_major_cells...]. Rows and columns are each 1–16, and
  cells are signed-i64 encodings of 0 (empty), 1 (fresh), or 2 (rotten).
  Exact framing is required. The maximum valid input is 258 words; 259 words
  are parseable so trailing-value rejection can be checked.
- The bounded input contract also represents a null or empty grid with a
  null input pointer and length 0, [0, 0], or [rows, 0] for rows 1–16.
  A null pointer with nonzero length is invalid. These cases return 0. Ragged
  grids and cell values outside 0, 1, and 2 are outside the contract.
- The return value is the number of minutes until all fresh oranges rot, or
  -1 when some fresh orange is unreachable. A finite result is bounded by
  255 because a shortest path in a 256-cell grid visits at most 256 cells;
  this is a conservative ceiling. Malformed framing, dimensions, or cell
  values return INT64_MIN, which is distinct from the valid -1 result.
- The source queues all initially rotten cells, checks neighbors in
  up/right/down/left order, and returns 0 when there are no fresh cells.
  Neighbor order is not observable in the scalar result.

[workload.json](workload.json) covers empty and zero-width grids, already
rotten and all-fresh grids, multiple initial sources, reachable and blocked
layouts, a maximum-size grid, a 16-by-16 obstacle snake, and malformed inputs. The independent
[oracle](../../rotting_oranges_oracle.py) uses a queue-based multi-source BFS.

## Pinned source

The source is TheAlgorithms/Java [RottingOranges.run](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/graphs/RottingOranges.java)
at commit e43ec3897e48f23843972d02cd05a5bb1b6864a2.

## Build, record, and verify

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm rotting_oranges --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/r/rotting_oranges/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithm rotting_oranges --languages rust
```

## Language ports

| Language | Source |
| --- | --- |
| C | [c/r/rotting_oranges.c](../../../c/r/rotting_oranges.c) |
| C3 | [c3/r/rotting_oranges.c3](../../../c3/r/rotting_oranges.c3) |
| C++ | [cpp/r/rotting_oranges.cpp](../../../cpp/r/rotting_oranges.cpp) |
| Elisa | [elisa/r/rotting_oranges.elisa](../../../elisa/r/rotting_oranges.elisa) |
| Nim | [nim/r/rotting_oranges.nim](../../../nim/r/rotting_oranges.nim) |
| Odin | [odin/r/rotting_oranges.odin](../../../odin/r/rotting_oranges.odin) |
| Rust | [rust/r/rotting_oranges.rs](../../../rust/r/rotting_oranges.rs) |
| V | [v/r/rotting_oranges.v](../../../v/r/rotting_oranges.v) |
| Zig | [zig/r/rotting_oranges.zig](../../../zig/r/rotting_oranges.zig) |
