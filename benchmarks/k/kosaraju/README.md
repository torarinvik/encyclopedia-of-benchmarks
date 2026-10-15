# Kosaraju strongly connected components

This benchmark finds strongly connected components in a directed graph with the two-pass Kosaraju method: DFS finishing order, then DFS over the transposed graph. It covers every vertex, including isolated vertices, and every component.

## Contract

- Input is `[vertex_count, edge_count, (source, target) * edge_count]` with zero-based IDs.
- There are 0–40 vertices and 0–2,047 packed directed edges. The exact input length is `2 + 2 * edge_count`.
- Repeated directed edges are coalesced. Self-loops are allowed. All vertices are included even when they have no incident edges.
- Invalid input returns `-1`.
- Output is `[component_count, (component_size, sorted_vertex_ids...) * component_count]`, one byte per value. Vertices within a component are ascending; components are sorted by their vertex lists. The result is the output byte count.
- If the output buffer is too small, the function returns `-2` without writing output. Empty graphs encode as `[0]`.

[`workload.json`](workload.json) is shared with [`tarjan_scc`](../../t/tarjan_scc/workload.json), so both algorithms receive identical graph inputs and expected partitions. Runtime verification is pending.

## Pinned source mapping

These candidates use Kosaraju's two-pass strategy and map to this package:

- [C++ `kosaraju.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/graph/kosaraju.cpp) and [the C++-1 mirror](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/graph/kosaraju.cpp)
- [C `strongly_connected_components.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/graphs/strongly_connected_components.c)
- [Python `scc_kosaraju.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/scc_kosaraju.py) and [Python `strongly_connected_components.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/strongly_connected_components.py)
- [Go `kosaraju.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/graph/kosaraju.go)
- [Java `Kosaraju.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/graphs/Kosaraju.java)
- [JavaScript `Kosaraju.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Graphs/Kosaraju.js)
- [Rust `kosaraju.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/graph/kosaraju.rs)
- [R `kosaraju_scc.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/graph_algorithms/kosaraju_scc.r)
- Java [`StronglyConnectedComponentOptimized.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/graph/StronglyConnectedComponentOptimized.java) also uses finishing order and a transpose, despite its name.

The C# [`Kosaraju.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Graph/Kosaraju.cs) filename candidate is excluded from the alias mapping: it pushes vertices before finishing DFS and its second pass follows the original graph rather than the transpose, so it does not implement the same SCC partition on all directed graphs. The C candidate has a fixed 40-entry stack, so the shared vertex limit is 40. The C++ candidate scans one extra adjacency slot when building the transpose; the benchmark uses an explicit vertex count. Go's map traversal and the sources' DFS-dependent component order are normalized by the sorted output contract. JavaScript discovers vertices from edges, so the benchmark additionally represents isolated vertices explicitly.
