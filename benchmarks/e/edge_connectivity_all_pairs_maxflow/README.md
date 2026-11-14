# Edge connectivity by all-pairs maximum flow

This benchmark computes the global edge connectivity of a small undirected
graph. For each unordered pair of vertices, it treats every undirected edge as
unit capacity, runs an s-t maximum flow, and returns the least flow value. A
disconnected input graph therefore returns zero.

## Contract

The exported scalar ABI is `edge_connectivity_all_pairs_maxflow` with
`i64_array_scalar` input `[N,M,(u,v)*M]`. Vertices are zero-based. The graph is
simple and undirected: self-loops and repeated edges (including a reversed
duplicate) are invalid. The bounds are `2<=N<=10` and `0<=M<=45`; disconnected
graphs are valid. The frame length must equal `2+2*M` and cannot exceed 92
words. Invalid or null input returns `-1`.

The result is the minimum number of edges whose removal disconnects the graph.
The verifier source also compares generated simple graphs against the independent
vertex-connectivity oracle and their minimum degree using the standard inequality
`vertex connectivity <= edge connectivity <= minimum degree`; it has not run.
The primary implementation uses bounded Edmonds–Karp searches for every
terminal pair. The independent oracle enumerates all nontrivial vertex cuts
and counts crossing edges directly. The all-pairs flow method is distinct from
the local [`stoer_wagner`](../../s/stoer_wagner/README.md) phase-contraction method,
even though both return the same global-cut value. It also differs from
[`vertex_connectivity`](../../v/vertex_connectivity/README.md), which splits vertices
to compute vertex separators.

The input has maximum valid and parseable lengths of 92 and 93 i64 words. The
fixed workspace budget is 4096 bytes. Fixture metadata is in
[`workload.json`](workload.json).

## Source and rights

The all-pairs unit-capacity max-flow method is described in CP-Algorithms'
[Edge connectivity / Vertex connectivity article](https://cp-algorithms.com/graph/edge_vertex_connectivity.html#edge-connectivity-using-maximum-flow).
The article is licensed CC BY-SA 4.0. This package uses only the high-level
algorithm description; ports, oracles, bounds, and fixtures are clean-room.
See [`RIGHTS.md`](RIGHTS.md).

## Language ports

| Language | Source |
| --- | --- |
| C | [`edge_connectivity_all_pairs_maxflow.c`](../../../c/e/edge_connectivity_all_pairs_maxflow.c) |
| C3 | [`edge_connectivity_all_pairs_maxflow.c3`](../../../c3/e/edge_connectivity_all_pairs_maxflow.c3) |
| C++ | [`edge_connectivity_all_pairs_maxflow.cpp`](../../../cpp/e/edge_connectivity_all_pairs_maxflow.cpp) |
| Elisa | [`edge_connectivity_all_pairs_maxflow.elisa`](../../../elisa/e/edge_connectivity_all_pairs_maxflow.elisa) |
| Mojo | [`edge_connectivity_all_pairs_maxflow.mojo`](../../../mojo/e/edge_connectivity_all_pairs_maxflow.mojo) |
| Nim | [`edge_connectivity_all_pairs_maxflow.nim`](../../../nim/e/edge_connectivity_all_pairs_maxflow.nim) |
| Odin | [`edge_connectivity_all_pairs_maxflow.odin`](../../../odin/e/edge_connectivity_all_pairs_maxflow.odin) |
| Rust | [`edge_connectivity_all_pairs_maxflow.rs`](../../../rust/e/edge_connectivity_all_pairs_maxflow.rs) |
| V | [`edge_connectivity_all_pairs_maxflow.v`](../../../v/e/edge_connectivity_all_pairs_maxflow.v) |
| Zig | [`edge_connectivity_all_pairs_maxflow.zig`](../../../zig/e/edge_connectivity_all_pairs_maxflow.zig) |

Static package and fixture inventory is described by
[`verify_edge_connectivity_all_pairs_maxflow_package.py`](../../verify_edge_connectivity_all_pairs_maxflow_package.py).
