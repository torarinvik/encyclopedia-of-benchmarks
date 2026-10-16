# Bipartite graph by DFS

Decide whether an undirected graph can be colored with two colors so every edge connects different colors. This follows the pinned Java implementation: it starts a DFS from each still-uncolored vertex, so disconnected components are checked too. The ports use an explicit stack for the same coloring decision.

Pinned source:

- Java: [TheAlgorithms/Java `BipartiteGraphDFS.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/graphs/BipartiteGraphDFS.java)
- Python: [`check_bipatrite.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/check_bipatrite.py) includes both DFS and BFS coloring variants; on this contract their decisions agree.

## Contract

Input is a signed 64-bit array `[vertex_count, edge_count, (u, v)...]`. The vertex count is 1 through 64, the edge count is 0 through 256, and vertex IDs are zero-based. Each input pair creates an undirected edge. Repeated edges are accepted and do not change the result. Self-loops are accepted and make the graph non-bipartite, matching the source coloring check.

The function returns 1 if the graph is bipartite, 0 if it is not, and `-1` for malformed input or an endpoint outside the graph. It returns only the decision; the source's coloring assignment and DFS order are internal details.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/bipartite_graph_dfs.c`](../../../c/b/bipartite_graph_dfs.c) |
| C3 | [`c3/b/bipartite_graph_dfs.c3`](../../../c3/b/bipartite_graph_dfs.c3) |
| C++ | [`cpp/b/bipartite_graph_dfs.cpp`](../../../cpp/b/bipartite_graph_dfs.cpp) |
| Elisa | [`elisa/b/bipartite_graph_dfs.elisa`](../../../elisa/b/bipartite_graph_dfs.elisa) |
| Nim | [`nim/b/bipartite_graph_dfs.nim`](../../../nim/b/bipartite_graph_dfs.nim) |
| Odin | [`odin/b/bipartite_graph_dfs.odin`](../../../odin/b/bipartite_graph_dfs.odin) |
| Rust | [`rust/b/bipartite_graph_dfs.rs`](../../../rust/b/bipartite_graph_dfs.rs) |
| V | [`v/b/bipartite_graph_dfs.v`](../../../v/b/bipartite_graph_dfs.v) |
| Zig | [`zig/b/bipartite_graph_dfs.zig`](../../../zig/b/bipartite_graph_dfs.zig) |
