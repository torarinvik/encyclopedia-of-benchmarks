# A* path search (Python grid variant)

This benchmark ports the pinned [TheAlgorithms/Python `astar`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/astar.py) grid implementation. The world is an open rectangular grid: the source creates an all-zero NumPy matrix but does not use it to block cells. Each move reaches one of the eight neighbors in the source's listed order and costs one. The source score is `g + h`, where `h = (goal_y - y)^2 + (goal_x - x)^2`.

## Contract

- Input is `[rows, columns, start_x, start_y, goal_x, goal_y]`; each dimension is 1..16 and both coordinates must lie inside the grid.
- The output is the source-returned path as signed i64 little-endian coordinate pairs `(x,y)`, including both endpoints. The return value is the number of output bytes.
- The source's first minimum-score entry wins ties. It appends every in-bounds neighbor in the listed order; its nested `continue` statements do not skip already-seen positions, so this package preserves those duplicate expansions and parent links.
- Malformed or out-of-grid input returns `-1`. Insufficient output capacity returns `-2` without writing output. Every valid in-grid pair is reachable in this obstacle-free world.
- The fixed open/node workspace has 256 entries. For dimensions up to 16, a direct path has at most 15 steps. With squared Euclidean distance, the goal-directed neighbor has the unique lowest `f` score at each step, so the source pops only that path before reaching the goal and generates at most `1 + 8*15 = 121` node records. The workspace bound therefore does not reject any input in the documented domain.

[`workload.json`](workload.json) covers diagonal, rectangular, reverse, single-row, and same-position paths, invalid input, and insufficient capacity. Coordinates and dimensions stay within the bound above.

## Workload and build

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm astar --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/a/astar/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/a/astar.c`](../../../c/a/astar.c) |
| C3 | [`c3/a/astar.c3`](../../../c3/a/astar.c3) |
| C++ | [`cpp/a/astar.cpp`](../../../cpp/a/astar.cpp) |
| Elisa | [`elisa/a/astar.elisa`](../../../elisa/a/astar.elisa) |
| Nim | [`nim/a/astar.nim`](../../../nim/a/astar.nim) |
| Odin | [`odin/a/astar.odin`](../../../odin/a/astar.odin) |
| Rust | [`rust/a/astar.rs`](../../../rust/a/astar.rs) |
| V | [`v/a/astar.v`](../../../v/a/astar.v) |
| Zig | [`zig/a/astar.zig`](../../../zig/a/astar.zig) |
