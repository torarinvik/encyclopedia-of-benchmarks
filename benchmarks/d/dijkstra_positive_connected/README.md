# Dijkstra shortest distances on a bounded connected graph

This package maps the pinned C#, Java, and Python single-source shortest-path implementations to a small common domain. It returns every distance from source vertex 0 in vertex-ID order.

## Contract

- Input is `[vertex_count, edge_count, (u,v,weight)...]` as signed 64-bit integers, with exact packing and no trailing fields.
- There are 2 through 4 vertices and between `n-1` and `n*(n-1)/2` edges. Each undirected edge is listed once. The graph must be simple and connected; source vertex 0 is fixed. Weights are positive integers from 1 through 255.
- Output is one signed i64 shortest distance per vertex, in ascending vertex order, encoded little-endian. The function returns the output byte count.
- Malformed or out-of-domain input returns `-1`; insufficient output capacity or a null output buffer returns `-2`.

The small connected graph bound keeps the Python source's custom priority queue in the reviewed safe region and ensures all vertices are present in its adjacency map. A one-vertex, zero-edge graph is excluded because that source attempts to access a missing adjacency entry for the source vertex. Positive weights avoid the Java source's zero-means-no-edge convention. The C# source expects source vertex index 0 to be enqueued first; the fixed source satisfies that assumption.

## Pinned sources

- [TheAlgorithms/C-Sharp `DijkstraAlgorithm.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Graph/Dijkstra/DijkstraAlgorithm.cs)
- [TheAlgorithms/Java `DijkstraAlgorithm.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/graphs/DijkstraAlgorithm.java)
- [TheAlgorithms/Python `dijkstra_algorithm.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/dijkstra_algorithm.py)

[`workload.json`](workload.json) covers weighted shortcuts, maximum edge weights, equal-distance routes, a two-vertex graph, and malformed/disconnected inputs.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/d/dijkstra_positive_connected.c`](../../../c/d/dijkstra_positive_connected.c) |
| C3 | [`c3/d/dijkstra_positive_connected.c3`](../../../c3/d/dijkstra_positive_connected.c3) |
| C++ | [`cpp/d/dijkstra_positive_connected.cpp`](../../../cpp/d/dijkstra_positive_connected.cpp) |
| Elisa | [`elisa/d/dijkstra_positive_connected.elisa`](../../../elisa/d/dijkstra_positive_connected.elisa) |
| Nim | [`nim/d/dijkstra_positive_connected.nim`](../../../nim/d/dijkstra_positive_connected.nim) |
| Odin | [`odin/d/dijkstra_positive_connected.odin`](../../../odin/d/dijkstra_positive_connected.odin) |
| Rust | [`rust/d/dijkstra_positive_connected.rs`](../../../rust/d/dijkstra_positive_connected.rs) |
| V | [`v/d/dijkstra_positive_connected.v`](../../../v/d/dijkstra_positive_connected.v) |
| Zig | [`zig/d/dijkstra_positive_connected.zig`](../../../zig/d/dijkstra_positive_connected.zig) |
