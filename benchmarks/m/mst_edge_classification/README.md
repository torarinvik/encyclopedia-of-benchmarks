# Minimum-spanning-tree edge classification

This benchmark classifies each input edge by its role across **all** minimum
spanning trees of one connected, weighted, undirected graph. Output follows
input edge order: `0` means an edge appears in no MST, `1` means it appears in
some but not all MSTs, and `2` means it appears in every MST.

## Contract

Input is `[N,M,(u,v,w)*M]` with `1 <= N <= 12`, `0 <= M <= 24`, zero-based
canonical endpoints `0 <= u < v < N`, no repeated undirected pair, and weights
in `[0,20]`. The graph must be connected; a disconnected graph is invalid. The
single-vertex graph with no edges is valid. The maximum valid input has 74
signed 64-bit words, and one output byte is written per edge (at most 24
bytes). Invalid input returns `-1`; a null output buffer or insufficient
capacity returns `-2` when at least one byte is required. Errors leave the
output untouched.

The primary ports order edge IDs by weight and process one equal-weight group
at a time. A disjoint-set structure represents components formed by strictly
lighter edges. Each candidate edge becomes an edge-ID-preserving edge in the
group's contracted multigraph. A candidate is class `2` exactly when deleting
that edge disconnects its quotient component; other candidates are class `1`.
Edges already internal to a lighter component remain class `0`. The group is
unioned only after its classifications are complete. Keeping edge IDs in the
quotient graph is necessary because distinct input edges can become parallel
after contraction. This bounded edge-deletion bridge check costs
`O(N + M^2 N)` time and `O(N+M)` auxiliary storage; this bounded implementation
uses insertion sorting and a direct edge-ID deletion search for each quotient
edge.

The independent oracle does not build quotient graphs: it computes the
baseline MST weight, then forces and forbids each edge in separate Kruskal
recomputations. An edge is critical if forbidding it raises the optimum or
disconnects the graph; it is pseudo-critical if forcing it preserves the
optimum after it is known not to be critical; otherwise it belongs to no MST.

## Distinctness and provenance

The candidate was discovered from the public LeetCode title index only. No
problem statement, examples, tests, submissions, or site code were
consulted or copied. Local [`second_best_mst`](../../s/second_best_mst/README.md)
returns a strictly heavier alternative tree, while [`bridges`](../../b/bridges/README.md)
and [`two_edge_connected_components`](../../t/two_edge_connected_components/README.md)
describe unweighted connectivity cuts. [`kkt_mst_sampling_filter`](../../k/kkt_mst_sampling_filter/README.md)
classifies edges as light or heavy relative to one sampled minimum spanning
forest. These operations do not classify edge participation across all
minimum-weight spanning trees of the original graph.

The clean-room method uses the Kruskal ordering and disjoint-set contraction
described by [CP-Algorithms: Kruskal minimum spanning tree](https://cp-algorithms.com/graph/mst_kruskal.html)
and the edge-removal definition of a bridge from
[CP-Algorithms: finding bridges](https://cp-algorithms.com/graph/bridge-searching.html).
The site is licensed CC BY-SA 4.0; only the high-level algorithm descriptions
were consulted. See [RIGHTS.md](RIGHTS.md), the
[`workload.json`](workload.json), and the package-local static inventory
checker.

## Language ports

| Language | Port |
| --- | --- |
| C | [`c/m/mst_edge_classification.c`](../../../c/m/mst_edge_classification.c) |
| C3 | [`c3/m/mst_edge_classification.c3`](../../../c3/m/mst_edge_classification.c3) |
| C++ | [`cpp/m/mst_edge_classification.cpp`](../../../cpp/m/mst_edge_classification.cpp) |
| Elisa | [`elisa/m/mst_edge_classification.elisa`](../../../elisa/m/mst_edge_classification.elisa) |
| Mojo | [`mojo/m/mst_edge_classification.mojo`](../../../mojo/m/mst_edge_classification.mojo) |
| Nim | [`nim/m/mst_edge_classification.nim`](../../../nim/m/mst_edge_classification.nim) |
| Odin | [`odin/m/mst_edge_classification.odin`](../../../odin/m/mst_edge_classification.odin) |
| Rust | [`rust/m/mst_edge_classification.rs`](../../../rust/m/mst_edge_classification.rs) |
| V | [`v/m/mst_edge_classification.v`](../../../v/m/mst_edge_classification.v) |
| Zig | [`zig/m/mst_edge_classification.zig`](../../../zig/m/mst_edge_classification.zig) |

This source-only package has not been compiled or run.
