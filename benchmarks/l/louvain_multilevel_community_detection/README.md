# Louvain multilevel community detection

This bounded profile implements the two-phase Louvain heuristic for weighted
undirected graphs: local modularity-improving moves followed by aggregation of
each community into a weighted supernode. It finds a heuristic partition and
does not claim a global modularity optimum.

Input is `[n,m,(u,v,w)*m]`. The graph has `2<=n<=8`, `1<=m<=28`, and each
simple undirected edge is listed once with `u<v`, pair records in strictly
increasing lexicographic order, and weight `1..7`. Isolated vertices are
allowed. The exact input length is `2+3*m`; maximum valid length is 86 words,
with 87 parseable words to reject a trailing value. Invalid framing, fields,
or null input return `-1`.

At each level every current node starts in its own community. Visit nodes in
ascending minimum-original-vertex order and repeat sweeps until a sweep makes
no moves. For a node, consider only communities of adjacent other nodes. Move
to the target with the greatest strictly positive modularity gain; ties use
the target community's minimum original vertex ID before the move. If no
target has positive gain, keep the node where it is. Aggregate the resulting
communities in ascending minimum-original-vertex order, summing cross-community
weights and keeping internal directed weight on the diagonal as the standard
doubled self-loop value. Reinitialize singleton communities on the quotient
graph and repeat until a level makes no move.

The implementation compares exact integer scores
`S = (sum_i degree_i) * internal_directed_weight - sum_C(total_degree_C^2)`.
Since `S=4*M^2*Q` for total undirected edge weight `M`, it has exactly the same
ordering as modularity `Q` and avoids floating-point ties. The output packs
`(community_count << 24) | label_code`; `label_code` stores each original
vertex's canonical community label (the minimum original vertex ID) in its
three-bit slot. The maximum result is 150,994,943.

The primary oracle builds quotient adjacency matrices with doubled diagonal
self-loops. The independent oracle retains the original graph and supernode
membership sets, recomputing full modularity after each candidate move. Both
follow the same pinned node order and tie rule. With `k` current nodes, a
candidate score takes O(k^2), a move considers at most k targets, and at most
O(M^2) strict integer-score improvements occur per level. Across at most n
levels, the conservative bound is O(M^2 n^4) time and O(n^2) space. The small
graph contract favors deterministic cross-language semantics over large-graph
throughput.

Source: Vincent D. Blondel, Jean-Loup Guillaume, Renaud Lambiotte, and Etienne
Lefebvre, “Fast unfolding of communities in large networks,” *Journal of
Statistical Mechanics: Theory and Experiment* (2008), DOI
10.1088/1742-5468/2008/10/P10008. The visitation order and tie refinements are
benchmark choices; the source paper itself notes that output depends on node
order. See [`RIGHTS.md`](RIGHTS.md).

ABI: `i64_array_scalar`, symbol `louvain_multilevel_community_detection`.

| Language | Port |
|---|---|
| C | `c/l/louvain_multilevel_community_detection.c` |
| C3 | `c3/l/louvain_multilevel_community_detection.c3` |
| C++ | `cpp/l/louvain_multilevel_community_detection.cpp` |
| Elisa | `elisa/l/louvain_multilevel_community_detection.elisa` |
| Mojo | `mojo/l/louvain_multilevel_community_detection.mojo` |
| Nim | `nim/l/louvain_multilevel_community_detection.nim` |
| Odin | `odin/l/louvain_multilevel_community_detection.odin` |
| Rust | `rust/l/louvain_multilevel_community_detection.rs` |
| V | `v/l/louvain_multilevel_community_detection.v` |
| Zig | `zig/l/louvain_multilevel_community_detection.zig` |
