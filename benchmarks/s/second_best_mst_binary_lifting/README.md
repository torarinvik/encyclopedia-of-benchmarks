# Strictly heavier second-best MST by binary lifting

This in-progress benchmark uses Kruskal to construct a deterministic minimum
spanning tree, then answers fundamental-cycle path queries with binary lifting.
Each jump stores the two largest distinct edge weights on its path. The
existing [`second_best_mst`](../second_best_mst/README.md) finds these weights
by walking each tree path; ordinary binary-lifting LCA and ancestor packages
do not aggregate them. The lifting table changes the measured preprocessing
and query behavior.

The intended `i64_array_scalar` input is `[N,M,(u,v,w)*M]`, where
`1<=N<=8`, `N-1<=M<=20`, `0<=u<v<N`, no endpoint pair is repeated,
`0<=w<=1000000`, and the graph is connected. Kruskal sorts by weight and
input edge ID. Return one plus the least spanning-tree weight strictly larger
than the minimum, or zero if none exists; return -1 for null or malformed
input. The maximum valid and parseable lengths are 62 and 63 words. The
positive offset separates a zero answer from valid weight zero.

Build a rooted tree, depths, ancestors, and top-two-distinct path summaries.
For every edge outside the MST, query its tree path. If its weight exceeds
the path maximum, exchange that maximum; if equal, exchange the second
distinct maximum if one exists. Minimize the resulting strictly positive
increase. Some bounded drafts use stable insertion sorting in `O(M²)` and
unranked disjoint-set linking, whose `M` root searches take at most `O(MN)`
in the worst case. Table construction costs `O(N log N)` and path queries
cost `O(M log N)`. The fixed adjacency and duplicate-check arrays used by
some drafts require `O(N² + M + N log N)` auxiliary storage; the abstract
adjacency-list formulation uses `O(M + N log N)`.

Every tree has `N-1` edges, so its weight is at most 7,000,000 and an
encoded success result is at most 7,000,001. All weight sums and sentinel
values fit in signed 64-bit integers.

The method follows [CP-Algorithms' second-best MST discussion](https://cp-algorithms.com/graph/second_best_mst.html)
(CC BY-SA 4.0); algorithm ideas only, with independent code and fixtures. The
primary reference uses lifting, and an independent reference enumerates spanning
trees. A workload, package inventory checker, drafts in all ten languages,
and scalar-suite registration are present. All require validation; nothing
has been run.

The workload includes a length-seven path and a path crossing two branches,
both with an entering edge tied with the path maximum. These require selecting
the second distinct path weight to obtain a strictly heavier tree.

## Language drafts

| Language | Source |
| --- | --- |
| C | [`second_best_mst_binary_lifting.c`](../../../c/s/second_best_mst_binary_lifting.c) |
| C3 | [`second_best_mst_binary_lifting.c3`](../../../c3/s/second_best_mst_binary_lifting.c3) |
| C++ | [`second_best_mst_binary_lifting.cpp`](../../../cpp/s/second_best_mst_binary_lifting.cpp) |
| Elisa | [`second_best_mst_binary_lifting.elisa`](../../../elisa/s/second_best_mst_binary_lifting.elisa) |
| Mojo | [`second_best_mst_binary_lifting.mojo`](../../../mojo/s/second_best_mst_binary_lifting.mojo) |
| Nim | [`second_best_mst_binary_lifting.nim`](../../../nim/s/second_best_mst_binary_lifting.nim) |
| Odin | [`second_best_mst_binary_lifting.odin`](../../../odin/s/second_best_mst_binary_lifting.odin) |
| Rust | [`second_best_mst_binary_lifting.rs`](../../../rust/s/second_best_mst_binary_lifting.rs) |
| V | [`second_best_mst_binary_lifting.v`](../../../v/s/second_best_mst_binary_lifting.v) |
| Zig | [`second_best_mst_binary_lifting.zig`](../../../zig/s/second_best_mst_binary_lifting.zig) |
