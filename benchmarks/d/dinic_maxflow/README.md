# Dinic maximum flow

Compute the maximum flow from a source to a sink in a bounded directed capacitated graph using Dinic's level graph and blocking-flow method.

## Contract

- `i64_array_scalar` input is `[vertex_count, edge_count, source, sink, (from, to, capacity)*edge_count]`.
- Vertex count is 2..16; edge count is 0..64. Source, sink, and edge endpoints use 1-based IDs in the packed input, and source and sink must differ. Self-loops are invalid; parallel and antiparallel edges are allowed.
- Capacities are integers in 0..100. Packed length must be exactly `4 + 3*edge_count`. The total flow is at most 6,400 under these bounds.
- Return the maximum flow, including 0 when no augmenting path exists, or -1 for invalid input.

## Source semantics

The ports use BFS to label the residual level graph, then DFS to send blocking flow while retaining a per-vertex current-edge cursor. Parallel edges sum into the same directed capacity, matching the matrix-based Java and R versions. The Rust source numbers vertices from 1, while Java and both Python sources use 0-based IDs; the R source also uses 1-based IDs. The packed contract normalizes IDs to 1-based and all ports adapt them internally.

The sources use different residual representations and iteration details: Java stores a capacity matrix and returns from BFS when it discovers the sink; Python `graphs/dinic.py` adds capacity-scaling phases; Python `networking_flow/dinic.py` and Rust use paired residual edges; R accumulates parallel capacities in a matrix and also returns cut metadata. Under this benchmark's nonnegative bounded capacities, valid distinct source/sink, no-self-loop contract, each computes the same maximum-flow scalar. The benchmark remains the Dinic algorithm; it is separate from Edmonds–Karp and Ford–Fulkerson.

## Workload

[`workload.json`](workload.json) covers the classic six-vertex network, disconnected flow, parallel and antiparallel edges, zero capacity, empty edge lists, and malformed graph inputs. The source-backed expected-value check is in [`benchmarks/run_i64_array_scalar.py`](../../run_i64_array_scalar.py).

## Pinned sources

- [Java `Dinic.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/graph/Dinic.java)
- [Python `graphs/dinic.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/dinic.py)
- [Python `networking_flow/dinic.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/networking_flow/dinic.py)
- [R `dinic_max_flow.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/graph_algorithms/dinic_max_flow.r)
- [Rust `dinic_maxflow.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/graph/dinic_maxflow.rs)

## Ports

| Language | Source |
| --- | --- |
| C | [`c/d/dinic_maxflow.c`](../../../c/d/dinic_maxflow.c) |
| C3 | [`c3/d/dinic_maxflow.c3`](../../../c3/d/dinic_maxflow.c3) |
| C++ | [`cpp/d/dinic_maxflow.cpp`](../../../cpp/d/dinic_maxflow.cpp) |
| Elisa | [`elisa/d/dinic_maxflow.elisa`](../../../elisa/d/dinic_maxflow.elisa) |
| Nim | [`nim/d/dinic_maxflow.nim`](../../../nim/d/dinic_maxflow.nim) |
| Odin | [`odin/d/dinic_maxflow.odin`](../../../odin/d/dinic_maxflow.odin) |
| Rust | [`rust/d/dinic_maxflow.rs`](../../../rust/d/dinic_maxflow.rs) |
| V | [`v/d/dinic_maxflow.v`](../../../v/d/dinic_maxflow.v) |
| Zig | [`zig/d/dinic_maxflow.zig`](../../../zig/d/dinic_maxflow.zig) |
