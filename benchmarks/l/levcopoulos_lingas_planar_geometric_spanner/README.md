# Levcopoulos–Lingas planar geometric spanner

This package profiles Algorithm 3.1 from §3 of Levcopoulos and Lingas's
planar-network construction. Its input contains the coordinates and a canonical
Delaunay edge set; the measured operation computes the Euclidean MST of that
triangulation, doubles the tree into its embedded contour, and absorbs exposed
Delaunay triangles using a LIFO boundary stack. It keeps a shortcut exactly
when the accumulated boundary-path weight is strictly greater than twice the
Euclidean shortcut length (`r=1`), otherwise that accumulated weight is carried
onto the boundary shortcut.

The input is `[n, (x,y)*n, m, (u,v)*m]`: `3<=n<=8`, integer coordinates in
`[-10,10]`, and `3<=m<=18`. Point IDs are input order and each edge satisfies
`0<=u<v<n`; edges are unique and lexicographically ordered. The supplied edge
set must be the Delaunay triangulation of the points. Duplicate points,
collinear triples, and cocircular quadruples are invalid. The package checks
the triangulation by enumerating its empty-circumcircle faces. Coordinates and
triangulation therefore form a small, explicit prerequisite; constructing the
triangulation itself is covered by
[`delaunay_triangulation`](../../d/delaunay_triangulation/README.md).

Every geometric rotation is sorted counterclockwise by exact integer
half-plane/cross-product comparison. The Euclidean MST uses increasing
`(squared_length,u,v)` order. Its initial directed contour begins with the
smallest directed tree edge `(u,v)` and follows the clockwise successor at each
target. The contour is re-anchored at its lexicographically smallest dart after
each absorption. Initial stack entries are pushed in contour order; after an
absorption, the right-side exposed candidate is pushed first and the left-side
candidate second, so the left candidate is popped first. This pins the
otherwise unspecified tie order. The two changed boundary corners are tested
through the paper's `next` and `cnext` rotation conditions; an ineligible or
stale stack dart is skipped. Binary64 square roots are rounded per edge;
the accumulated path weight is summed left to right and compared with
`2*sqrt(squared_length)` using strict `>`.

The output is `[absorbed_face_count, retained_shortcut_count, edge_count,
(u,v)*edge_count]`. The first counter counts processed boundary faces; the
second counts retained edges beyond the MST. Retained undirected edges are
sorted lexicographically.
Malformed input returns `-1`; null or short output returns `-2` without writes.
At most 18 edges are emitted (312 bytes maximum); the package stages output in
512 bytes and declares 8,192 bytes of workspace.

## References and duplicate decision

The primary reference follows the paper's directed polygon, `next`/`cnext`
rotation relations, stack, and accumulated-weight test. The independent
reference records exposed triangle events and scans the bounded boundary
state. Both validate the exact Delaunay edge prerequisite and use the same
documented deterministic stack profile.

This is distinct from the full
[`delaunay_triangulation`](../../d/delaunay_triangulation/README.md), which returns
all triangles; [`euclidean_t_spanner`](../../e/euclidean_t_spanner/README.md),
which chooses representative pairs from a WSPD; and
[`weighted_greedy_spanner`](../../s/weighted_greedy_spanner/README.md), which
uses increasing-weight shortest-path tests on a general weighted graph. The
Levcopoulos–Lingas operation removes Delaunay edges by expanding a doubled MST
contour and carries hidden boundary-path weights.

Primary source: Christos Levcopoulos and Andrzej Lingas, “There Are Planar
Graphs Almost as Good as the Complete Graphs and Almost as Cheap as Minimum
Spanning Trees,” *Algorithmica* 8 (1992), 251–256, Algorithm 3.1 and Lemmas
3.1–3.3, [DOI 10.1007/BF01758846](https://doi.org/10.1007/BF01758846). The
corresponding *Encyclopedia of Algorithms* entry is Chapter 294,
[DOI 10.1007/978-1-4939-2864-4_294](https://doi.org/10.1007/978-1-4939-2864-4_294).
Only the mathematical procedure was used; no source code, prose, figures, or
fixtures were reused. See [RIGHTS.md](RIGHTS.md).

## Workload and ports

The bounded [workload](workload.json) includes convex sets with no absorbed
faces, an interior-point triangulation with an exposed-face absorption and a
two-step case that retains a shortcut after carrying path weight, malformed
edge sets, capacity failure, and null pointers. The two reference
implementations are [`primary_oracle.py`](primary_oracle.py) and
[`independent_oracle.py`](independent_oracle.py). Native ports use the
`levcopoulos_lingas_planar_geometric_spanner` export.

| Fixture | Coverage |
| --- | --- |
| `triangle_mst_no_interior_face` | Smallest valid triangulation; no face absorption. |
| `convex_quadrilateral_no_absorption` | Convex triangulation with no exposed interior face. |
| `interior_point_absorbs_exposed_face` | Exercises an exposed-face absorption and carried path weight. |
| `carried_path_triggers_retained_shortcut` | Four carried-face absorptions precede an `A-B` shortcut where the final path weight is strictly over twice the chord. |
| `duplicate_delaunay_edge` | Rejects a repeated, noncanonical edge list. |
| `collinear_points_rejected` | Rejects a degenerate point set. |
| `null_input` | Null input returns `-1`. |
| `null_output` | Null output returns `-2` without writes. |
| `short_output_capacity` | Capacity below the 56-byte triangle result returns `-2` without writes. |
| `invalid_before_null_output` | Invalid input keeps `-1` precedence even when output is null. |

The fixture IDs and their order are repeated in [`inventory.json`](inventory.json);
[`check_inventory.py`](check_inventory.py) cross-checks that list against the
workload and the ten source paths.

In `carried_path_triggers_retained_shortcut`, the points are A=(0,3),
P=(-1,0), Q=(2,0), B=(5,3), C=(-5,-10). The Delaunay faces are APQ, AQB,
APC, PQC, and QBC; the MST edges are AP, PQ, QB, and PC. The fixed stack
processes APC, PQC, QBC, then APQ, carrying each path weight. APQ leaves
`w(AQ)=sqrt(10)+3`; the next AQB step has path weight
`sqrt(10)+3+sqrt(18) ~= 10.4049`, strictly above `2*|AB|=10`, so AB is
retained. The output header is `[absorbed=5, shortcuts=1, edges=5]`.

| Language | Port |
| --- | --- |
| C | [`c/l/levcopoulos_lingas_planar_geometric_spanner.c`](../../../c/l/levcopoulos_lingas_planar_geometric_spanner.c) |
| C3 | [`c3/l/levcopoulos_lingas_planar_geometric_spanner.c3`](../../../c3/l/levcopoulos_lingas_planar_geometric_spanner.c3) |
| C++ | [`cpp/l/levcopoulos_lingas_planar_geometric_spanner.cpp`](../../../cpp/l/levcopoulos_lingas_planar_geometric_spanner.cpp) |
| Elisa | [`elisa/l/levcopoulos_lingas_planar_geometric_spanner.elisa`](../../../elisa/l/levcopoulos_lingas_planar_geometric_spanner.elisa) |
| Mojo | [`mojo/l/levcopoulos_lingas_planar_geometric_spanner.mojo`](../../../mojo/l/levcopoulos_lingas_planar_geometric_spanner.mojo) |
| Nim | [`nim/l/levcopoulos_lingas_planar_geometric_spanner.nim`](../../../nim/l/levcopoulos_lingas_planar_geometric_spanner.nim) |
| Odin | [`odin/l/levcopoulos_lingas_planar_geometric_spanner.odin`](../../../odin/l/levcopoulos_lingas_planar_geometric_spanner.odin) |
| Rust | [`rust/l/levcopoulos_lingas_planar_geometric_spanner.rs`](../../../rust/l/levcopoulos_lingas_planar_geometric_spanner.rs) |
| V | [`v/l/levcopoulos_lingas_planar_geometric_spanner.v`](../../../v/l/levcopoulos_lingas_planar_geometric_spanner.v) |
| Zig | [`zig/l/levcopoulos_lingas_planar_geometric_spanner.zig`](../../../zig/l/levcopoulos_lingas_planar_geometric_spanner.zig) |

The ten source ports, references, workload, rights notice, package-local
inventory, and shared runner, verifier, and catalog registration are now
integrated. No programs, tests, scripts, checkers, builds, compilers, profilers,
or benchmarks were run.
