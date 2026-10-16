# Eulerian trail in a simple undirected graph

This package finds an Eulerian circuit or open trail in a simple undirected graph. The benchmark preserves the pinned Python implementation's depth first traversal order and start-node rules: circuits start at vertex 1, while an open trail starts at the highest-labeled odd-degree vertex. Each adjacency list follows the input edge order.

Input is `[vertex_count, edge_count, u0, v0, ...]` in signed 64-bit slots. `vertex_count` is 2 through 10, labels are in `[0, vertex_count)`, and `edge_count` is 0 through 45. The input must contain exactly two endpoint slots per edge. Self-loops, duplicate undirected edges, disconnected nonzero-degree vertices, and graphs with an odd-degree count other than 0 or 2 are invalid. For a nonempty circuit, vertex 1 must be incident to an edge. The empty-edge case returns the one-vertex circuit `[1]`.

Output is `[status, vertex_count, trail_vertices...]` encoded as little-endian signed 64-bit values. Status `1` means circuit; status `2` means open trail. Invalid input returns `-1`; a null or undersized output buffer returns `-2`. The return value on success is the number of output bytes.

| Language | Port |
|---|---|
| C | [`c/e/eulerian_trail_undirected_simple.c`](../../../c/e/eulerian_trail_undirected_simple.c) |
| C3 | [`c3/e/eulerian_trail_undirected_simple.c3`](../../../c3/e/eulerian_trail_undirected_simple.c3) |
| C++ | [`cpp/e/eulerian_trail_undirected_simple.cpp`](../../../cpp/e/eulerian_trail_undirected_simple.cpp) |
| Elisa | [`elisa/e/eulerian_trail_undirected_simple.elisa`](../../../elisa/e/eulerian_trail_undirected_simple.elisa) |
| Nim | [`nim/e/eulerian_trail_undirected_simple.nim`](../../../nim/e/eulerian_trail_undirected_simple.nim) |
| Odin | [`odin/e/eulerian_trail_undirected_simple.odin`](../../../odin/e/eulerian_trail_undirected_simple.odin) |
| Rust | [`rust/e/eulerian_trail_undirected_simple.rs`](../../../rust/e/eulerian_trail_undirected_simple.rs) |
| V | [`v/e/eulerian_trail_undirected_simple.v`](../../../v/e/eulerian_trail_undirected_simple.v) |
| Zig | [`zig/e/eulerian_trail_undirected_simple.zig`](../../../zig/e/eulerian_trail_undirected_simple.zig) |

Pinned source: [TheAlgorithms/Python `eulerian_path_and_circuit_for_undirected_graph.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/eulerian_path_and_circuit_for_undirected_graph.py). The source's printed wrapper is excluded; graph construction and traversal semantics are retained. See [`workload.json`](workload.json) for representative cases.
