# OI Wiki maximum clique branch and bound

This bounded profile returns the maximum clique cardinality of a simple,
undirected, loopless graph. It implements the ordered search from OI Wiki's
first `MaxClique` solver: process possible minimum clique vertices from high
to low, visit each candidate suffix in increasing order, and intersect that
suffix with the chosen vertex's neighbors.

The DFS prunes with two upper bounds. The number of remaining candidate
vertices bounds the number of possible additions. A second bound adds the
current clique size to `dp[u]`, the best clique already found in the vertex
suffix starting at candidate `u`. Once a root search improves the global best,
it can stop: the incumbent before that root was the best clique among larger
IDs, so a clique containing the root can exceed it by at most one.

## Contract

Input is `[n, adjacency_mask_0, ..., adjacency_mask_(n-1)]`, with
`0 <= n <= 24`. Each signed-i64 mask must be nonnegative, contain only bits in
`[0,n)`, omit its own vertex bit, and agree symmetrically with every other
row. The exact frame length is `1+n`: the maximum valid and parseable lengths
are 25 and 26 words. The extra parseable word is reserved for rejecting a
trailing-value frame. Invalid input returns `-1`; an empty graph returns 0;
otherwise the result is the maximum clique size in `[1,n]`.

Worst-case search remains exponential, `O(2^n poly(n))`, with recursion depth
at most 24. The declared workspace is 16384 bytes for the fixed adjacency,
suffix-bound, and bounded recursive state, including value-passed fixed arrays.

This is distinct from [`maximum_independent_set`](../../m/maximum_independent_set/README.md),
which uses maximum-induced-degree branching and a greedy clique-cover bound.
It also differs from [`bron_kerbosch`](../../b/bron_kerbosch/README.md), which
enumerates maximal cliques, [`clique_reverse_search_enumeration`](../../r/clique_reverse_search_enumeration/README.md),
which enumerates all cliques, and [`gbbs_k_clique_count`](../../g/gbbs_k_clique_count/README.md),
which counts fixed-size cliques.

The primary reference mirrors ordered candidate intersections and suffix
pruning. The independent reference enumerates every vertex subset and checks
all selected vertex pairs; the package workload uses that exhaustive reference
for fixtures with at most 16 vertices. Maximum-size complete and path fixtures
have hand-derived expected values and are statically checked against the
primary reference.

See [`workload.json`](workload.json), [`primary_oracle.py`](primary_oracle.py),
[`independent_oracle.py`](independent_oracle.py), and [`RIGHTS.md`](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [`c/o/oi_wiki_maximum_clique_branch_bound.c`](../../../c/o/oi_wiki_maximum_clique_branch_bound.c) |
| C3 | [`c3/o/oi_wiki_maximum_clique_branch_bound.c3`](../../../c3/o/oi_wiki_maximum_clique_branch_bound.c3) |
| C++ | [`cpp/o/oi_wiki_maximum_clique_branch_bound.cpp`](../../../cpp/o/oi_wiki_maximum_clique_branch_bound.cpp) |
| Elisa | [`elisa/o/oi_wiki_maximum_clique_branch_bound.elisa`](../../../elisa/o/oi_wiki_maximum_clique_branch_bound.elisa) |
| Mojo | [`mojo/o/oi_wiki_maximum_clique_branch_bound.mojo`](../../../mojo/o/oi_wiki_maximum_clique_branch_bound.mojo) |
| Nim | [`nim/o/oi_wiki_maximum_clique_branch_bound.nim`](../../../nim/o/oi_wiki_maximum_clique_branch_bound.nim) |
| Odin | [`odin/o/oi_wiki_maximum_clique_branch_bound.odin`](../../../odin/o/oi_wiki_maximum_clique_branch_bound.odin) |
| Rust | [`rust/o/oi_wiki_maximum_clique_branch_bound.rs`](../../../rust/o/oi_wiki_maximum_clique_branch_bound.rs) |
| V | [`v/o/oi_wiki_maximum_clique_branch_bound.v`](../../../v/o/oi_wiki_maximum_clique_branch_bound.v) |
| Zig | [`zig/o/oi_wiki_maximum_clique_branch_bound.zig`](../../../zig/o/oi_wiki_maximum_clique_branch_bound.zig) |
