# Hierholzer Eulerian path

This package ports the pinned Java directed-graph Hierholzer implementation. It is separate from [`hierholzer_algorithm`](../hierholzer_algorithm/README.md), which handles undirected Eulerian circuits and returns a scalar hash.

## Contract

- ABI: `i64_array_bytes_output`.
- Input is `[vertex_count, edge_count, (source, destination)...]`, with `vertex_count` in `0..16`, `edge_count` in `0..48`, and exact length `2 + 2*edge_count`. Every endpoint must be in `0..vertex_count-1`. Directed duplicate edges are preserved in input order.
- A nonempty graph with edges is accepted when it satisfies the directed Euler path degree rules and all vertices with nonzero degree are weakly connected. Exactly one `outdegree - indegree == 1` vertex and one `-1` vertex select an open path; if every degree balances, the first vertex with outgoing edges in ascending id order is the circuit start. Other degree patterns have no route.
- The ports consume each vertex's outgoing edges in input order while using an explicit stack, then reverse the completed walk as the source does. A structurally valid graph without one Euler route returns an empty path.
- `vertex_count == 0` returns an empty path. A nonempty graph with no edges returns `[0]`, even if it declares other isolated vertices.
- Output is an i64 vertex count followed by that many signed-i64 vertex ids, all little-endian. The status is the number of output bytes, `8*(vertex_count_in_path + 1)`. Even an empty path writes the eight-byte zero count. Maximum output is 400 bytes.
- Malformed input returns `-1`. A null output buffer or capacity below the serialized byte count returns `-2` without writes.

Pinned source: [TheAlgorithms/Java `HierholzerEulerianPath.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/graph/HierholzerEulerianPath.java).

[`workload.json`](workload.json) covers empty and edgeless graphs, directed paths and circuits, FIFO edge order, isolated vertices, duplicate edges, the input limits, no-route cases, malformed records, and output errors. The independent [oracle](../../hierholzer_eulerian_path_oracle.py) serializes the path count and vertex ids.

| Language | Port |
|---|---|
| C | [`c/h/hierholzer_eulerian_path.c`](../../../c/h/hierholzer_eulerian_path.c) |
| C3 | [`c3/h/hierholzer_eulerian_path.c3`](../../../c3/h/hierholzer_eulerian_path.c3) |
| C++ | [`cpp/h/hierholzer_eulerian_path.cpp`](../../../cpp/h/hierholzer_eulerian_path.cpp) |
| Elisa | [`elisa/h/hierholzer_eulerian_path.elisa`](../../../elisa/h/hierholzer_eulerian_path.elisa) |
| Nim | [`nim/h/hierholzer_eulerian_path.nim`](../../../nim/h/hierholzer_eulerian_path.nim) |
| Odin | [`odin/h/hierholzer_eulerian_path.odin`](../../../odin/h/hierholzer_eulerian_path.odin) |
| Rust | [`rust/h/hierholzer_eulerian_path.rs`](../../../rust/h/hierholzer_eulerian_path.rs) |
| V | [`v/h/hierholzer_eulerian_path.v`](../../../v/h/hierholzer_eulerian_path.v) |
| Zig | [`zig/h/hierholzer_eulerian_path.zig`](../../../zig/h/hierholzer_eulerian_path.zig) |
