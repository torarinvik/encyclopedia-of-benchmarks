# Bipartite minimum vertex cover

This bounded profile constructs a minimum vertex-cover certificate for a
bipartite graph. Its primary method finds a maximum matching with ordered DFS
augmenting paths, then applies alternating reachability from unmatched left
vertices. Kőnig's theorem guarantees that the resulting cover has the same size
as the matching.

Input is `[left_count, right_count, left_adjacency_mask_0, ...]`, with each
partition bounded by 8. A bit in a left row selects the corresponding right
vertex. The frame must contain exactly `2 + left_count` signed 64-bit values;
the maximum valid length is 10 and the maximum parseable length is 11. Invalid
frames return `-1`.

The scalar result is a packed cover mask. Bits `0..left_count-1` identify
selected left vertices; bit `left_count+j` identifies right vertex `j`. The
mask is a certificate, not just the cover cardinality. To make it stable when
several minimum covers exist, the profile chooses the lexicographically
smallest membership vector in the order left vertices then right vertices,
with `0` before `1`. After the alternating-reachability step establishes the
minimum size, the primary refines the certificate by considering vertices in
that order and preserving an exclusion whenever another matching-feasibility
check shows a cover of the same minimum size remains possible.

The independent reference enumerates all vertex subsets, tests edge coverage,
and selects the same canonical minimum mask. It is bounded to at most 16 total
vertices. The primary runs in `O(V^2 E)` time for the canonical refinement on
this profile, with `O(V+E)` fixed workspace; one matching and alternating
reachability pass alone take `O(VE)`.

This benchmark measures the construction of a concrete bipartite cover. It is
distinct from [`bipartite_matching_kuhn`](../bipartite_matching_kuhn/README.md),
which returns only matching cardinality, and from
[`dulmage_mendelsohn`](../../d/dulmage_mendelsohn/README.md),
which classifies vertices into invariant E/O/U regions, and from
[`greedy_min_vertex_cover`](../greedy_min_vertex_cover/README.md) and general
vertex-cover search/kernelization packages. KACTL's maximum matching is used
as an algorithm-description source, not as a copied implementation.

Sources: KACTL [`MinimumVertexCover.h`](https://github.com/kth-competitive-programming/kactl/blob/main/content/graph/MinimumVertexCover.h)
and [`DFSMatching.h`](https://github.com/kth-competitive-programming/kactl/blob/main/content/graph/DFSMatching.h).
Both headers identify their algorithm snippets as CC0. The ports and
references here are clean-room implementations based on the descriptions;
see [`RIGHTS.md`](RIGHTS.md).

See [`workload.json`](workload.json), [`primary_oracle.py`](primary_oracle.py),
[`independent_oracle.py`](independent_oracle.py), and
[`INVENTORY.md`](INVENTORY.md). The package is registered in
`benchmarks/run_i64_array_scalar.py` and `benchmarks/verify_i64_array_scalar.py`.

## Language ports

| Language | Source |
|---|---|
| C | [`c/b/bipartite_minimum_vertex_cover.c`](../../../c/b/bipartite_minimum_vertex_cover.c) |
| C3 | [`c3/b/bipartite_minimum_vertex_cover.c3`](../../../c3/b/bipartite_minimum_vertex_cover.c3) |
| C++ | [`cpp/b/bipartite_minimum_vertex_cover.cpp`](../../../cpp/b/bipartite_minimum_vertex_cover.cpp) |
| Elisa | [`elisa/b/bipartite_minimum_vertex_cover.elisa`](../../../elisa/b/bipartite_minimum_vertex_cover.elisa) |
| Mojo | [`mojo/b/bipartite_minimum_vertex_cover.mojo`](../../../mojo/b/bipartite_minimum_vertex_cover.mojo) |
| Nim | [`nim/b/bipartite_minimum_vertex_cover.nim`](../../../nim/b/bipartite_minimum_vertex_cover.nim) |
| Odin | [`odin/b/bipartite_minimum_vertex_cover.odin`](../../../odin/b/bipartite_minimum_vertex_cover.odin) |
| Rust | [`rust/b/bipartite_minimum_vertex_cover.rs`](../../../rust/b/bipartite_minimum_vertex_cover.rs) |
| V | [`v/b/bipartite_minimum_vertex_cover.v`](../../../v/b/bipartite_minimum_vertex_cover.v) |
| Zig | [`zig/b/bipartite_minimum_vertex_cover.zig`](../../../zig/b/bipartite_minimum_vertex_cover.zig) |
