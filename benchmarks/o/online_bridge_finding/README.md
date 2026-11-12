# Online Bridge Finding

Maintain the number of bridges in an undirected graph as edges are inserted, returning the count after every insertion.

## Contract

The bounded packed-array ABI accepts `[n, m, u_0, v_0, ..., u_(m-1), v_(m-1)]`. There are `1..64` vertices and `0..128` edge insertions; endpoints are zero-based and may repeat or form self-loops. The output is one little-endian signed 64-bit bridge count per inserted edge, in insertion order. An empty insertion sequence returns zero bytes. Invalid input returns `-1`; a null or undersized output buffer returns `-2` when output is nonempty.

The online algorithm maintains a disjoint-set structure for connected components and another for 2-edge-connected components, along with a forest of current bridges. An edge joining two connected components becomes a bridge; an edge inside a connected component closes a cycle and removes the bridges along that cycle. The smaller connected tree is rerooted when components join. The implementation uses fixed bounds of 64 vertices and 128 insertions.

## Distinctness from local graph packages

[`bridges`](../bridges/README.md) finds all cut edges once for a complete static graph. [`gbbs_biconnectivity`](../../g/gbbs_biconnectivity/README.md) labels static vertex-biconnected edge blocks; [`three_edge_connected_components`](../../t/three_edge_connected_components/README.md) labels static 3-edge-connected vertex classes; and [`two_edge_connected_spanning_subgraph_greedy`](../../t/two_edge_connected_spanning_subgraph_greedy/README.md) selects a static sparse subgraph. [`decremental_connectivity`](../../d/decremental_connectivity/README.md) handles edge deletions in forests, [`single_source_dynamic_reachability_rebuild`](../../s/single_source_dynamic_reachability_rebuild/README.md) rebuilds directed reachability after updates, and [`incremental_scc`](../../i/incremental_scc/README.md) handles directed insertions and strong components. [`two_level_dynamic_maximal_matching_insertions`](../../t/two_level_dynamic_maximal_matching_insertions/README.md) also handles undirected insertions but maintains a matching. These packages do not maintain bridge counts under incremental undirected edge insertion. The graph-adjacency packages replay storage operations without online bridge maintenance.

This package is a bounded clean-room implementation of the [CP-Algorithms online bridge-finding algorithm](https://cp-algorithms.com/graph/bridge-searching-online.html). The source article accepts an initially empty graph and reports the bridge count after every inserted edge; this ABI packs a bounded insertion trace into one call. See [`workload.json`](workload.json) and [`benchmarks/online_bridge_finding_oracle.py`](../../online_bridge_finding_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/o/online_bridge_finding.c`](../../../c/o/online_bridge_finding.c) |
| C3 | [`c3/o/online_bridge_finding.c3`](../../../c3/o/online_bridge_finding.c3) |
| C++ | [`cpp/o/online_bridge_finding.cpp`](../../../cpp/o/online_bridge_finding.cpp) |
| Elisa | [`elisa/o/online_bridge_finding.elisa`](../../../elisa/o/online_bridge_finding.elisa) |
| Mojo | [`mojo/o/online_bridge_finding.mojo`](../../../mojo/o/online_bridge_finding.mojo) |
| Nim | [`nim/o/online_bridge_finding.nim`](../../../nim/o/online_bridge_finding.nim) |
| Odin | [`odin/o/online_bridge_finding.odin`](../../../odin/o/online_bridge_finding.odin) |
| Rust | [`rust/o/online_bridge_finding.rs`](../../../rust/o/online_bridge_finding.rs) |
| V | [`v/o/online_bridge_finding.v`](../../../v/o/online_bridge_finding.v) |
| Zig | [`zig/o/online_bridge_finding.zig`](../../../zig/o/online_bridge_finding.zig) |
