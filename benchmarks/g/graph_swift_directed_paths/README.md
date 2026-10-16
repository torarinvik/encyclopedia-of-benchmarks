# Swift Directed Graph Paths

This package ports the pinned Swift graph protocol and adjacency-list implementation. It exposes the source's depth-first and breadth-first path searches over a directed graph.

## Contract

Input is a signed 64-bit array `[vertex_count, edge_count, (from, to)..., query_count, (mode, start, destination)...]`. There are 1 to 32 vertices, 0 to 256 edge records, and 1 to 64 queries. Vertices are numbered from zero. Edges are directed, and vertex IDs are in topological order, and each edge must go from a lower ID to a higher ID; this makes the input a DAG and keeps the source's recursive DFS finite. Duplicate edges are accepted. Each vertex's outgoing edges retain their input order, which determines the first DFS path and can determine which BFS path is selected. Mode 0 is DFS and mode 1 is BFS.

For each query, output contains the edge count followed by the destination vertex at each step of the path, all as little-endian signed i64 values. A count of `-1` means no path; a count of zero means the start already equals the destination. The function returns bytes written. Invalid input returns `-1`; a null or undersized output buffer returns `-2` without writing.

The workload covers DFS versus shortest BFS choices, insertion order, duplicate edges, equal endpoints, unreachable destinations, the edge and query bounds, invalid input, and insufficient output capacity.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm graph_swift_directed_paths --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/g/graph_swift_directed_paths/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/g/graph_swift_directed_paths.c`](../../../c/g/graph_swift_directed_paths.c) |
| C3 | [`c3/g/graph_swift_directed_paths.c3`](../../../c3/g/graph_swift_directed_paths.c3) |
| C++ | [`cpp/g/graph_swift_directed_paths.cpp`](../../../cpp/g/graph_swift_directed_paths.cpp) |
| Elisa | [`elisa/g/graph_swift_directed_paths.elisa`](../../../elisa/g/graph_swift_directed_paths.elisa) |
| Nim | [`nim/g/graph_swift_directed_paths.nim`](../../../nim/g/graph_swift_directed_paths.nim) |
| Odin | [`odin/g/graph_swift_directed_paths.odin`](../../../odin/g/graph_swift_directed_paths.odin) |
| Rust | [`rust/g/graph_swift_directed_paths.rs`](../../../rust/g/graph_swift_directed_paths.rs) |
| V | [`v/g/graph_swift_directed_paths.v`](../../../v/g/graph_swift_directed_paths.v) |
| Zig | [`zig/g/graph_swift_directed_paths.zig`](../../../zig/g/graph_swift_directed_paths.zig) |

## Pinned source

- Swift [`graph/Graph.swift`](https://github.com/TheAlgorithms/Swift/blob/2c9eb8b85dee6db46cb33452c0b904eb7d7d179c/graph/Graph.swift)
