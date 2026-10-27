# Kirkpatrick hierarchical point-location query

This package profiles the query phase of the hierarchical-triangulation
approach described in “Point Location,” DOI
[`10.1007/978-1-4939-2864-4_587`](https://doi.org/10.1007/978-1-4939-2864-4_587).
The coarsest level has one triangle. For a query, the implementation examines
the supplied ordered list of finer-level triangles that intersect the
currently selected triangle, then descends to the unique triangle containing
the query. The hierarchy, its face IDs, and its candidate lists are supplied
preprocessing output; this benchmark does not construct the hierarchy.

Input is
`[V,L,qx,qy,(x,y)*V, level_0_faces_and_candidates, ..., level_(L-1)_faces]`.
Each level starts with its face count followed by that many triples of vertex
IDs. After every nonfinal level, each face contributes a candidate count and
its child face IDs in strictly increasing local-ID order. The top level has
exactly one face. Bounds are `3<=V<=16`, `1<=L<=4`, at most eight faces per
level, and integer coordinates in `[-1000,1000]`. Triangles must be
counterclockwise and nondegenerate. Every listed candidate must geometrically
intersect its coarse face. The query must be strictly inside exactly one face
at each level, so shared-boundary choices do not arise.

The query scans candidate IDs in increasing order. The returned fixed
16-byte payload contains two signed little-endian i64 values: the face ID in
the finest level, followed by the exact number of point-in-triangle tests.
That count includes the top-level test and candidate tests up to and including
the first containing candidate at each descent. Structural validation tests
are excluded from the count. Malformed inputs return `-1`; null output or
capacity below 16 returns `-2` without writing.

This is a bounded supplied-hierarchy query profile, not a measurement of
Kirkpatrick hierarchy construction or its preprocessing bounds. The primary
oracle checks triangle intersections by edge/vertex tests; the independent
verifier uses separating-axis overlap checks and area-sum containment.

| Language | Port |
|---|---|
| C | `c/k/kirkpatrick_hierarchical_point_location.c` |
| C3 | `c3/k/kirkpatrick_hierarchical_point_location.c3` |
| C++ | `cpp/k/kirkpatrick_hierarchical_point_location.cpp` |
| Elisa | `elisa/k/kirkpatrick_hierarchical_point_location.elisa` |
| Nim | `nim/k/kirkpatrick_hierarchical_point_location.nim` |
| Odin | `odin/k/kirkpatrick_hierarchical_point_location.odin` |
| Rust | `rust/k/kirkpatrick_hierarchical_point_location.rs` |
| V | `v/k/kirkpatrick_hierarchical_point_location.v` |
| Zig | `zig/k/kirkpatrick_hierarchical_point_location.zig` |
