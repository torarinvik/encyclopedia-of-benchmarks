# A* on a directed weighted graph (Rust variant)

This package ports the pinned [TheAlgorithms/Rust `astar`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/graph/astar.rs) routine. The source stores directed outgoing edges, accepts a caller-provided heuristic, and returns `Option<(cost, path)>`. The benchmark uses a bounded integer graph and a consistent heuristic so the search returns a shortest path.

## Contract

Input is a signed i64 array:

`[vertex_count, edge_count, source, target, h(0)..h(V-1), (from,to,weight)...]`

There are 1..32 vertices and 0..128 directed edges. Vertex IDs are zero-based. Edge weights and heuristic values are in 0..1,000,000. The target heuristic is zero, and every edge must satisfy `h(from) <= weight + h(to)`. Parallel edges and self edges are allowed. This consistent-heuristic condition allows a popped vertex to be closed while preserving shortest-path results. The ports select the open vertex by `(g+h, g, vertex_id)` to make equal-priority paths deterministic across languages; the pinned Rust heap compares candidates by `g+h` only.

For a reachable target, output is a little-endian signed i64 vector `[path_cost, vertex_count, source, ..., target]`. The return value is the byte count. An unreachable target returns zero with no output; `source == target` returns cost zero and a one-vertex path. Malformed input returns `-1`; insufficient output capacity returns `-2` without writing.

[`workload.json`](workload.json) covers weighted directionality, unreachable reverse travel, deterministic ties, a zero-weight edge, source-equals-target, invalid heuristics and weights, malformed length, and output capacity.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm astar_rust_directed_graph --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/a/astar_rust_directed_graph/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/astar_rust_directed_graph.c`](../../../c/a/astar_rust_directed_graph.c) |
| C3 | [`c3/a/astar_rust_directed_graph.c3`](../../../c3/a/astar_rust_directed_graph.c3) |
| C++ | [`cpp/a/astar_rust_directed_graph.cpp`](../../../cpp/a/astar_rust_directed_graph.cpp) |
| Elisa | [`elisa/a/astar_rust_directed_graph.elisa`](../../../elisa/a/astar_rust_directed_graph.elisa) |
| Nim | [`nim/a/astar_rust_directed_graph.nim`](../../../nim/a/astar_rust_directed_graph.nim) |
| Odin | [`odin/a/astar_rust_directed_graph.odin`](../../../odin/a/astar_rust_directed_graph.odin) |
| Rust | [`rust/a/astar_rust_directed_graph.rs`](../../../rust/a/astar_rust_directed_graph.rs) |
| V | [`v/a/astar_rust_directed_graph.v`](../../../v/a/astar_rust_directed_graph.v) |
| Zig | [`zig/a/astar_rust_directed_graph.zig`](../../../zig/a/astar_rust_directed_graph.zig) |

## Pinned source

- Rust [`astar.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/graph/astar.rs)
