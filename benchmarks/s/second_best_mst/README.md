# Strictly heavier second-best minimum spanning tree

Build a deterministic Kruskal minimum spanning tree, then examine each
non-tree edge. Adding one creates a fundamental cycle. The ports find the
largest and second-largest **distinct** edge weights on that tree path and
remove the edge that gives the cheapest strictly heavier tree. The output also
includes the entering and leaving edge IDs as a one-edge-exchange certificate.

## Contract

Input is `[N,M,(u,v,w)*M]`, with `1 <= N <= 8`, `N-1 <= M <= 20`, zero-based
endpoints satisfying `u < v`, no repeated undirected edges, and weights in
`[0,1,000,000]`. The graph must be connected. Edges are identified by their
input positions. Kruskal breaks equal-weight ties by input ID.

Output is four signed 64-bit little-endian values:

`[minimum_tree_weight, strictly_heavier_second_weight, entering_edge_id, leaving_edge_id]`.

If no strictly heavier spanning tree exists, the last three values are
`[-1,-1,-1]` after the MST weight. Malformed input returns `-1`; null or short
output returns `-2` without writing. The result uses 32 bytes.

The ports use Kruskal followed by an explicit tree-path walk for every
non-tree edge. With the bounded local graph this costs `O(M^2 + M*N)` time
for insertion sorting and adjacency-list traversal, and `O(N^2 + M)` space.
The cited article also describes the faster binary-lifting variant; this
bounded profile keeps the same edge-exchange algorithm and its distinct-weight
tie handling while using simpler path scans.

The oracle independently enumerates every `N-1` edge subset, checks whether it
is a spanning tree, and finds the least weight strictly above the MST. It then
checks the reported exchange certificate. Ordinary Prim, Kruskal, and Borůvka
packages return an MST only; this benchmark searches for the next strictly
heavier tree.

## Provenance

Algorithm idea: [CP-Algorithms — Second Best Minimum Spanning Tree](https://cp-algorithms.com/graph/second_best_mst.html).
The implementations are clean-room ports; no article code, prose, or test data
was reused. CP-Algorithms content is licensed CC BY-SA 4.0.

[`workload.json`](workload.json) covers unique and tied edge weights, no
strictly heavier tree, malformed/disconnected graphs, and output-buffer errors.

## Implementations

| Language | Port |
|---|---|
| C | [`c/s/second_best_mst.c`](../../../c/s/second_best_mst.c) |
| C3 | [`c3/s/second_best_mst.c3`](../../../c3/s/second_best_mst.c3) |
| C++ | [`cpp/s/second_best_mst.cpp`](../../../cpp/s/second_best_mst.cpp) |
| Elisa | [`elisa/s/second_best_mst.elisa`](../../../elisa/s/second_best_mst.elisa) |
| Mojo | [`mojo/s/second_best_mst.mojo`](../../../mojo/s/second_best_mst.mojo) |
| Nim | [`nim/s/second_best_mst.nim`](../../../nim/s/second_best_mst.nim) |
| Odin | [`odin/s/second_best_mst.odin`](../../../odin/s/second_best_mst.odin) |
| Rust | [`rust/s/second_best_mst.rs`](../../../rust/s/second_best_mst.rs) |
| V | [`v/s/second_best_mst.v`](../../../v/s/second_best_mst.v) |
| Zig | [`zig/s/second_best_mst.zig`](../../../zig/s/second_best_mst.zig) |
