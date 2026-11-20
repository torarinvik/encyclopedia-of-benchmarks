# Delaunay-rooted reverse search for convex polygon triangulations

This package counts all triangulations of a strictly convex point set with
`3<=n<=8`. Input is `[n,(x,y)*n,seed_diagonal_count,(u,v)*seed_diagonal_count]`.
The points are integer coordinates in `[-50,50]`, listed in strict
counterclockwise convex-hull order; no three are collinear and no four are
cocircular. The seed has exactly `n-3` lexicographically ordered internal
diagonals and must be the unique Delaunay triangulation. Malformed frames or
an invalid seed return `-1`. A valid call returns the number of triangulations,
from 1 through 132. The maximum valid and parseable input lengths are 28 and 29
signed 64-bit words.

The primary uses exact integer orientation and incircle determinants. Starting
from the supplied Delaunay root, it scans the flip neighbors of each
triangulation in canonical diagonal order. For a candidate child, it computes
the parent by flipping that candidate's lexicographically smallest Lawson
edge. The child is visited only when that parent equals the current state.
This is the bounded reverse-search tree described in Chapter 729. An explicit
stack keeps the traversal workspace fixed; the convex `n<=8` profile has at
most Catalan(6)=132 states.

The independent reference enumerates every `n-3`-diagonal subset and counts
those with no crossing pair. It does not use the Lawson-edge parent rule or
reverse search. Both references validate the Delaunay seed before producing a
result.

The source is Chapter 729, [“Enumeration of Non-crossing Geometric Graphs”](https://doi.org/10.1007/978-1-4939-2864-4_729), which summarizes the Avis–Fukuda reverse-search method. The package uses the stated Lawson-edge parent rule as a method reference; its bounded input, validation, traversal, workload, and ports are clean-room. It differs from one-shot [`delaunay_triangulation`](../../delaunay_triangulation/README.md), which constructs one Delaunay triangulation, from `voronoi_delaunay_empty_circle`, which constructs the Delaunay graph, and from polygon optimization profiles, which return an optimum under a geometric objective.

| Language | Source |
|---|---|
| C | [`c/d/delaunay_rooted_triangulation_reverse_search.c`](../../../c/d/delaunay_rooted_triangulation_reverse_search.c) |
| C3 | [`c3/d/delaunay_rooted_triangulation_reverse_search.c3`](../../../c3/d/delaunay_rooted_triangulation_reverse_search.c3) |
| C++ | [`cpp/d/delaunay_rooted_triangulation_reverse_search.cpp`](../../../cpp/d/delaunay_rooted_triangulation_reverse_search.cpp) |
| Elisa | [`elisa/d/delaunay_rooted_triangulation_reverse_search.elisa`](../../../elisa/d/delaunay_rooted_triangulation_reverse_search.elisa) |
| Mojo | [`mojo/d/delaunay_rooted_triangulation_reverse_search.mojo`](../../../mojo/d/delaunay_rooted_triangulation_reverse_search.mojo) |
| Nim | [`nim/d/delaunay_rooted_triangulation_reverse_search.nim`](../../../nim/d/delaunay_rooted_triangulation_reverse_search.nim) |
| Odin | [`odin/d/delaunay_rooted_triangulation_reverse_search.odin`](../../../odin/d/delaunay_rooted_triangulation_reverse_search.odin) |
| Rust | [`rust/d/delaunay_rooted_triangulation_reverse_search.rs`](../../../rust/d/delaunay_rooted_triangulation_reverse_search.rs) |
| V | [`v/d/delaunay_rooted_triangulation_reverse_search.v`](../../../v/d/delaunay_rooted_triangulation_reverse_search.v) |
| Zig | [`zig/d/delaunay_rooted_triangulation_reverse_search.zig`](../../../zig/d/delaunay_rooted_triangulation_reverse_search.zig) |

The package-local static checker reviews metadata, workload framing, and source
paths only. It does not run either reference or any language port.
