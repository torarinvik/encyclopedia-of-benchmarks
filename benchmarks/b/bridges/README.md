# Bridges

This benchmark finds bridges, or cut edges, in an undirected graph with Tarjan discovery-time and low-link rules. It visits every connected component and returns normalized edges `(min(u, v), max(u, v))` in lexicographic order. This makes the output independent of DFS and adjacency-list order.

## Contract

- Input is `[vertex_count, edge_count, (left, right) * edge_count]` with zero-based vertex IDs.
- There are 0–64 vertices and 0–2,047 input edges. The input length must equal `2 + 2 * edge_count`.
- The graph is treated as simple: repeated and reversed edge pairs are coalesced. Self-loops are allowed and are never bridges.
- Every connected component is searched. Invalid input returns `-1`.
- Output is a flat byte sequence of sorted edge pairs. Each endpoint is one byte; the result is the output byte count. No bridges produces an empty byte sequence.
- If the output buffer is too small, the function returns `-2` without writing output.

[`workload.json`](workload.json) covers empty, connected and disconnected graphs, cycles, paths, self-loops, repeated edges, maximum-size inputs, and malformed cases. Runtime verification is pending.

## Pinned source mapping

These candidates implement the same cut-edge concept and map to this canonical `bridges` benchmark:

- [C++ bridge_finding_with_tarjan_algorithm.cpp](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/graph/bridge_finding_with_tarjan_algorithm.cpp)
- [C++-1 bridge_finding_with_tarjan_algorithm.cpp](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/graph/bridge_finding_with_tarjan_algorithm.cpp), a mirror with the same implementation
- [C# Bridges.cs](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Graph/Bridges.cs)
- [Python finding_bridges.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/finding_bridges.py)
- [Java TarjanBridges.java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/graph/TarjanBridges.java)
- [R bridge_detector.r](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/graph_algorithms/bridge_detector.r)

The C++ source explicitly assumes a connected graph and starts at vertex 0; the other candidates visit all components. Native result order and endpoint orientation vary, so this benchmark normalizes both. The simple-graph contract also coalesces duplicate edges before traversal, matching the one-edge-per-pair input expected by these implementations.
