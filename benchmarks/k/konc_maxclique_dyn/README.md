# Konc–Janežič MaxCliqueDyn

This bounded profile returns the maximum clique cardinality of a simple,
undirected, loopless graph. It follows the MaxCliqueDyn family: greedy
approximate coloring supplies upper bounds, branch and bound explores
intersections with each chosen vertex's neighborhood, and a deterministic
threshold periodically recomputes the candidate order by degree.

Input is `[n, adjacency_mask_0, ..., adjacency_mask_(n-1)]`, with
`0 <= n <= 24`. Every row is a nonnegative mask of neighbors in `[0,n)`, has
no self bit, and is symmetric with the corresponding row. Frames must contain
exactly `n+1` signed 64-bit words. The maximum valid frame has 25 words; a
26-word frame is parseable only so that extra data can be rejected. Invalid
input returns `-1`; the empty graph returns 0; other valid results lie in
`[1,n]`.

The initial order sorts by descending degree, then ascending vertex ID. For a
candidate subset, first-fit coloring places nonadjacent vertices in the same
class. Classes are concatenated in increasing color order; recursion visits
from the largest color down. Colors below `max(best-current_size+1,1)` cannot
improve the incumbent and are skipped. On a nonempty child set, the port
updates per-depth and global coloring counters and rebuilds its descending
degree order when `1000*prior_depth_count < 25*new_total_count`. This is the
fixed integer expression for the paper's `0.025` dynamic-tightening threshold.
Degree ties always use ascending vertex ID, which pins the bounded profile
across languages.

This computation differs from [`oi_wiki_maximum_clique_branch_bound`](../o/oi_wiki_maximum_clique_branch_bound/README.md), whose candidate order uses suffix intersections and a suffix-optimum bound. It also differs from [`maximum_independent_set`](../m/maximum_independent_set/README.md), which branches on maximum induced degree with a clique-cover bound. [`bron_kerbosch`](../b/bron_kerbosch/README.md) enumerates maximal cliques, while this package returns only the maximum cardinality.

The primary reference performs the bounded dynamic-coloring search. The
independent reference checks every vertex subset and every pair of selected
vertices for fixtures up to 16 vertices. The 24-vertex path and complete graph
have hand-derived results and are checked against the primary reference.
Worst-case time is exponential; the maximum profile is bounded to 24 vertices.
The declared workspace is 65,536 bytes for adjacency, candidate/color state,
the current clique, counters, and recursion frames.

Sources: Konc and Janežič, [*An Improved Branch and Bound Algorithm for the
Maximum Clique Problem*](https://insilab.org/articles/match2007.pdf), Section 2;
KACTL [`MaximumClique.h`](https://github.com/kth-competitive-programming/kactl/blob/main/content/graph/MaximumClique.h).
Only algorithm descriptions were used; the implementation is clean-room.
The package is registered in `benchmarks/run_i64_array_scalar.py` and
`benchmarks/verify_i64_array_scalar.py`.

See [`workload.json`](workload.json), [`primary_oracle.py`](primary_oracle.py),
[`independent_oracle.py`](independent_oracle.py), [`RIGHTS.md`](RIGHTS.md), and
[`INVENTORY.md`](INVENTORY.md).

## Language ports

| Language | Source |
|---|---|
| C | [`c/k/konc_maxclique_dyn.c`](../../../c/k/konc_maxclique_dyn.c) |
| C3 | [`c3/k/konc_maxclique_dyn.c3`](../../../c3/k/konc_maxclique_dyn.c3) |
| C++ | [`cpp/k/konc_maxclique_dyn.cpp`](../../../cpp/k/konc_maxclique_dyn.cpp) |
| Elisa | [`elisa/k/konc_maxclique_dyn.elisa`](../../../elisa/k/konc_maxclique_dyn.elisa) |
| Mojo | [`mojo/k/konc_maxclique_dyn.mojo`](../../../mojo/k/konc_maxclique_dyn.mojo) |
| Nim | [`nim/k/konc_maxclique_dyn.nim`](../../../nim/k/konc_maxclique_dyn.nim) |
| Odin | [`odin/k/konc_maxclique_dyn.odin`](../../../odin/k/konc_maxclique_dyn.odin) |
| Rust | [`rust/k/konc_maxclique_dyn.rs`](../../../rust/k/konc_maxclique_dyn.rs) |
| V | [`v/k/konc_maxclique_dyn.v`](../../../v/k/konc_maxclique_dyn.v) |
| Zig | [`zig/k/konc_maxclique_dyn.zig`](../../../zig/k/konc_maxclique_dyn.zig) |
