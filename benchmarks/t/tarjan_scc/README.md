# Tarjan strongly connected components

This benchmark finds strongly connected components in a directed graph with Tarjan's single-pass low-link and stack method. It covers every vertex, including isolated vertices, and every component.

## Contract

- Input is `[vertex_count, edge_count, (source, target) * edge_count]` with zero-based IDs.
- There are 0–40 vertices and 0–2,047 packed directed edges. The exact input length is `2 + 2 * edge_count`.
- Repeated directed edges are coalesced. Self-loops are allowed. All vertices are included even when they have no incident edges.
- Invalid input returns `-1`.
- Output is `[component_count, (component_size, sorted_vertex_ids...) * component_count]`, one byte per value. Vertices within a component are ascending; components are sorted by their vertex lists. The result is the output byte count.
- If the output buffer is too small, the function returns `-2` without writing output. Empty graphs encode as `[0]`.

[`workload.json`](workload.json) is shared with [`kosaraju`](../../k/kosaraju/workload.json), so both algorithms receive identical graph inputs and expected partitions. Runtime verification is pending.

## Pinned source mapping

These candidates use Tarjan's one-pass low-link and stack strategy and map to this package:

- [Python `tarjans_scc.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/tarjans_scc.py)
- [C# `TarjanStronglyConnectedComponents.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Graph/TarjanStronglyConnectedComponents.cs)
- Rust [`strongly_connected_components.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/graph/strongly_connected_components.rs) and the spelling variant [`tarjans_ssc.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/graph/tarjans_ssc.rs)
- TypeScript [`tarjan.ts`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/graph/tarjan.ts) and Java [`TarjansAlgorithm.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/graphs/TarjansAlgorithm.java) are additional Tarjan SCC implementations.

The Python candidate updates a back-edge low-link from the neighbor's low-link instead of its discovery index. The ports use the standard on-stack discovery-index update. The Rust generic-name candidate numbers vertices from 1, while the shared contract uses zero-based IDs. All native component orders are normalized to the shared sorted encoding.
