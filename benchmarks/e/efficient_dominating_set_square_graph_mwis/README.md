# Efficient domination through maximum-weight independent set

Decide whether a simple undirected graph has an efficient dominating set: a
vertex subset whose closed neighborhoods partition all vertices. The input is
`[n,edge_count,(u,v)*edge_count]`, with `1<=n<=12` and canonical endpoints
`0<=u<v<n`. Repeated edges, loops, reversed endpoint pairs, malformed lengths,
and out-of-range endpoints return `-1`. Return `1` if an efficient dominating
set exists and `0` otherwise. Maximum valid and parseable frame lengths are
134 and 135 signed 64-bit words.

The primary follows Chapter 689's reduction. It constructs the square graph
`G^2`, where vertices are adjacent when their distance in `G` is one or two,
and gives vertex `v` weight `degree_G(v)+1`. A maximum-weight independent set
in `G^2` has pairwise disjoint closed neighborhoods. Its weight reaches `n`
exactly when those neighborhoods cover every vertex, which is precisely an
efficient dominating set. The bounded search branches on the available vertex
with highest degree in the remaining square graph, breaking ties by smallest
ID, and explores inclusion before exclusion. A sum-of-remaining-weights upper
bound prunes the search. Some ports keep a global incumbent; others apply the
same bound to the exclusion branch after evaluating inclusion.

The independent reference enumerates vertex subsets and checks directly that
every graph vertex occurs in exactly one selected closed neighborhood. The
method comes from Chapter 689, [“Efficient Dominating and Edge Dominating Sets
for Graphs and Hypergraphs”](https://doi.org/10.1007/978-1-4939-2864-4_689).
This package measures the graph-to-square-graph weighted-independent-set
reduction. It differs from generic DLX (Algorithm X), tree-only independent
domination, and minimum domination that permits overlapping neighborhoods.
See [RIGHTS.md](RIGHTS.md) and [workload.json](workload.json).

| Language | Source |
|---|---|
| C | [`c/e/efficient_dominating_set_square_graph_mwis.c`](../../../c/e/efficient_dominating_set_square_graph_mwis.c) |
| C3 | [`c3/e/efficient_dominating_set_square_graph_mwis.c3`](../../../c3/e/efficient_dominating_set_square_graph_mwis.c3) |
| C++ | [`cpp/e/efficient_dominating_set_square_graph_mwis.cpp`](../../../cpp/e/efficient_dominating_set_square_graph_mwis.cpp) |
| Elisa | [`elisa/e/efficient_dominating_set_square_graph_mwis.elisa`](../../../elisa/e/efficient_dominating_set_square_graph_mwis.elisa) |
| Mojo | [`mojo/e/efficient_dominating_set_square_graph_mwis.mojo`](../../../mojo/e/efficient_dominating_set_square_graph_mwis.mojo) |
| Nim | [`nim/e/efficient_dominating_set_square_graph_mwis.nim`](../../../nim/e/efficient_dominating_set_square_graph_mwis.nim) |
| Odin | [`odin/e/efficient_dominating_set_square_graph_mwis.odin`](../../../odin/e/efficient_dominating_set_square_graph_mwis.odin) |
| Rust | [`rust/e/efficient_dominating_set_square_graph_mwis.rs`](../../../rust/e/efficient_dominating_set_square_graph_mwis.rs) |
| V | [`v/e/efficient_dominating_set_square_graph_mwis.v`](../../../v/e/efficient_dominating_set_square_graph_mwis.v) |
| Zig | [`zig/e/efficient_dominating_set_square_graph_mwis.zig`](../../../zig/e/efficient_dominating_set_square_graph_mwis.zig) |

The package-local static checker reviews metadata, workload framing, and source
paths only. It has not been run.
