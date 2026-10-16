# JavaScript Undirected Unweighted Graph

This benchmark ports the pinned JavaScript `Graph` class's `printGraph`, `bfs`, and `dfs` behavior for a bounded undirected, unweighted graph. Lowercase letter IDs keep JavaScript `Object.keys` in vertex insertion order. Each adjacency array retains edge insertion order and repeated neighbors; a self-loop appends the vertex twice because `addEdge` pushes to both endpoint arrays.

## Contract

Input is a signed 64-bit array `[vertex_count, vertex_id..., edge_count, endpoint_a, endpoint_b..., start_id]`. There are 1 through 26 distinct vertex IDs, each an ASCII lowercase letter (`a` through `z`), and 0 through 256 edges. Edge endpoints must be lowercase letters. As in the source, an edge whose endpoint is not a declared vertex is silently ignored. Duplicate vertices and a missing traversal start are excluded and return `-1`.

The output is a little-endian signed 64-bit vector:

```text
[vertex_count, (vertex_id, neighbor_count, neighbor_id...)*,
 bfs_count, (visited_vertex_id, level)*,
 dfs_count, visited_vertex_id...]
```

The adjacency rows follow vertex insertion order and each row keeps duplicate neighbors in edge insertion order. BFS uses the source's FIFO queue and reports each reachable vertex at its first dequeued level. DFS reports recursive pre-order while visiting neighbors in adjacency order. Both traversals start at the declared `start_id` and include only reachable vertices. Success returns the number of bytes written; malformed input returns `-1`; insufficient output capacity returns `-2`.

The packed input is at most 541 integers and the output at most 5,160 bytes. This bound allows the full 26-letter graph and 256 edges while keeping all storage fixed.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm graph_js_undirected_unweighted --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/g/graph_js_undirected_unweighted/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/g/graph_js_undirected_unweighted.c`](../../../c/g/graph_js_undirected_unweighted.c) |
| C3 | [`c3/g/graph_js_undirected_unweighted.c3`](../../../c3/g/graph_js_undirected_unweighted.c3) |
| C++ | [`cpp/g/graph_js_undirected_unweighted.cpp`](../../../cpp/g/graph_js_undirected_unweighted.cpp) |
| Elisa | [`elisa/g/graph_js_undirected_unweighted.elisa`](../../../elisa/g/graph_js_undirected_unweighted.elisa) |
| Nim | [`nim/g/graph_js_undirected_unweighted.nim`](../../../nim/g/graph_js_undirected_unweighted.nim) |
| Odin | [`odin/g/graph_js_undirected_unweighted.odin`](../../../odin/g/graph_js_undirected_unweighted.odin) |
| Rust | [`rust/g/graph_js_undirected_unweighted.rs`](../../../rust/g/graph_js_undirected_unweighted.rs) |
| V | [`v/g/graph_js_undirected_unweighted.v`](../../../v/g/graph_js_undirected_unweighted.v) |
| Zig | [`zig/g/graph_js_undirected_unweighted.zig`](../../../zig/g/graph_js_undirected_unweighted.zig) |

## Pinned source

- JavaScript [`Graph.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Graph/Graph.js)
