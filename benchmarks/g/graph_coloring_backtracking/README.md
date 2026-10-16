# Graph Coloring by Backtracking

This benchmark ports Go's `Graph.ColorUsingBacktracking`. It visits vertices in ascending ID order and tries colors `1` through the vertex count, also in ascending order. For each vertex it picks the first color not already used by a colored neighbor, then recursively continues. The output is the source method's coloring map normalized to vertex order, followed by the largest color used.

The pinned method allows as many colors as there are vertices. On the loopless graph domain below, at most `vertex - 1` earlier vertices can block colors, so the first available color always succeeds and the recursive search never backtracks. The benchmark preserves that source behavior; it does not search for a minimum coloring.

## Contract

- Input is `[vertex_count, edge_count, (u, v)...]`, with 0 through 64 vertices labeled densely from 0. All vertices exist before edges are added.
- Each edge is undirected. Endpoints must be distinct and in range. Repeated edges are accepted because the Go graph stores neighbors in sets. Self-loops are outside the coloring contract.
- Input length must be exactly `2 + 2 * edge_count`; edge count is bounded to 2,016.
- Output is `[vertex_count, color_0, ..., color_(vertex_count-1), colors_used]`, encoded as little-endian signed 64-bit values. An empty graph returns `[0, 0]`.
- The function returns the output byte count, `-1` for invalid input, and `-2` for insufficient output capacity without writing.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm graph_coloring_backtracking --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/g/graph_coloring_backtracking/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/graph_coloring_backtracking.c`](../../../c/g/graph_coloring_backtracking.c) |
| C3 | [`c3/b/graph_coloring_backtracking.c3`](../../../c3/g/graph_coloring_backtracking.c3) |
| C++ | [`cpp/b/graph_coloring_backtracking.cpp`](../../../cpp/g/graph_coloring_backtracking.cpp) |
| Elisa | [`elisa/b/graph_coloring_backtracking.elisa`](../../../elisa/g/graph_coloring_backtracking.elisa) |
| Nim | [`nim/b/graph_coloring_backtracking.nim`](../../../nim/g/graph_coloring_backtracking.nim) |
| Odin | [`odin/b/graph_coloring_backtracking.odin`](../../../odin/g/graph_coloring_backtracking.odin) |
| Rust | [`rust/b/graph_coloring_backtracking.rs`](../../../rust/g/graph_coloring_backtracking.rs) |
| V | [`v/b/graph_coloring_backtracking.v`](../../../v/g/graph_coloring_backtracking.v) |
| Zig | [`zig/b/graph_coloring_backtracking.zig`](../../../zig/g/graph_coloring_backtracking.zig) |

## Pinned source

- Go [`backtracking.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/graph/coloring/backtracking.go)
- Go graph structure [`graph.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/graph/coloring/graph.go)
