# Kanj–Perković modified-Yao selection pass

This package measures the fixed-parameter modified-Yao edge-selection pass
from Kanj and Perković, with `k=14`. It receives the graph, local cone labels,
and cyclic rotations as input, then returns the edges selected by both
endpoints. The benchmark isolates the selection procedure; it does not build
the Delaunay graph, classify geometric directions into cones, simulate
distributed messages, or measure the paper's stretch-factor proof.

## Contract

The `i64_array_scalar` frame is
`[n,m,(u,v,squared_length,cone_u,cone_v)*m,(degree,dart_ids...)*n]`.
Vertices satisfy `3<=n<=16`, and the connected simple graph has
`n-1<=m<=min(42,3n-6)`. Edges have `u<v`, are sorted lexicographically by
`(u,v)`, and use input order as their IDs. `squared_length` is positive and at
most `10^12`; comparing it gives the same shortest-edge order as comparing
Euclidean lengths. The maximum valid frame is 312 i64 words; one extra word is
parseable and rejected. The workspace cap is 16,384 bytes.

Each undirected edge has two darts: `2e` is directed from `u` to `v`, and
`2e+1` from `v` to `u`. A dart's cone field is local to its source vertex.
The fourteen equal-angle cones are numbered counterclockwise from a supplied
reference ray; cone `c` precedes cone `(c+1) mod 14`. The profile excludes
edges on cone boundaries, so every dart has one unambiguous cone ID in
`0..13`. The local CCW rotation begins at the reference ray, lists darts by
nondecreasing cone ID, and orders darts within a cone counterclockwise. The
caller supplies this geometric metadata; the
package checks framing, dart ownership, cone ordering, graph connectivity,
and genus-zero consistency of the rotation system. It does not verify that the
graph and metadata are realizable as a Delaunay triangulation. The source's
geometric stretch guarantee applies when its Delaunay-graph assumptions hold;
this package makes no such guarantee for an arbitrary supplied plane graph.

At each vertex, the pass first selects the shortest edge in every occupied
cone. It then handles each maximal cyclic run of empty cones. A run of length
`ell>1` selects `floor(ell/2)` previously unselected incident edges clockwise
from the run and `ceil(ell/2)` counterclockwise. A singleton run inspects the
nearest incident edge on each side: if one is selected, it selects the other;
if neither is selected, it selects the shorter. The local selected edge set
contains the directed choices made at that vertex. Output is one signed-i64
bitmask, with bit `e` set iff both endpoints select edge `e`.

The source leaves equal-length and iteration-order ties open. This package
refines them deterministically: compare squared lengths then edge ID, process
maximal cyclic empty runs by increasing starting cone ID (a start is empty
while its preceding cone is occupied), process the clockwise side before the
counterclockwise side, and use the lower edge ID in the singleton equal
length case. Clockwise scans move backward through the supplied CCW rotation,
starting at the final dart in the preceding occupied cone; counterclockwise
scans move forward, starting at the first dart in the following occupied
cone. For a run of length `ell>1`, each side skips darts already selected and
selects its prescribed count before the other side begins. A singleton run
inspects those two nearest boundary darts. Empty runs wrap modulo 14; a vertex
with all cones occupied has no gap pass. Output bit `e` is set only when both
endpoint-local directed selections contain the dart.

Input outside the structural contract returns `-1`. The algorithm makes one
pass over occupied cones, scans at most 14 cone positions per empty run, and
uses bounded local rotations. With `k` fixed, primary work is `O(n+m)` up to a
constant number of bounded side scans; space is `O(n+m+k*n)`. The widest
64-bit-index fixed-array layout uses at most 9,660 raw bytes for its arrays:
edge records 1,680; adjacency and degree counts 384; dart source/cone maps
1,344; rotation and position maps 1,344; row metadata 256; cone bucket bounds
3,584; seen/reachability/queue state 228; face traversal state 756; and
selection flags 84. The 16,384-byte workspace cap leaves room for alignment,
parser scalars, and call-local traversal state.

## Distinction and sources

The local [`levcopoulos_lingas_planar_geometric_spanner`](../levcopoulos_lingas_planar_geometric_spanner/README.md)
uses an MST contour, stack-based face absorption, and a carried path-weight
test to remove Delaunay edges. This package instead uses per-vertex cone
selection, empty-cone gap rules, and mutual endpoint selection to bound degree.
They are distinct constructions, not alternate implementations of the same
edge-selection algorithm.

Chapter context is Joachim Gudmundsson, Giri Narasimhan, and Michiel Smid,
“Planar Geometric Spanners,” *Encyclopedia of Algorithms*, Chapter 294,
[DOI 10.1007/978-1-4939-2864-4_294](https://doi.org/10.1007/978-1-4939-2864-4_294).
The operational procedure is Iyad A. Kanj and Ljubomir Perković, “On Geometric
Spanners of Euclidean and Unit Disk Graphs,” §2.3, Figure 3,
[DOI 10.4230/LIPIcs.STACS.2008.1320](https://doi.org/10.4230/LIPIcs.STACS.2008.1320).
The references were used for algorithm descriptions only. The implementation,
fixtures, and documentation are independently written.

See [RIGHTS.md](RIGHTS.md), [workload.json](workload.json),
[INVENTORY.md](INVENTORY.md), [INVENTORY.json](INVENTORY.json),
[primary_oracle.py](primary_oracle.py), and
[independent_oracle.py](independent_oracle.py), [verify_workload.py](verify_workload.py),
and [check_inventory.py](check_inventory.py).

| Language | Port |
|---|---|
| C | `c/k/kanj_perkovic_modified_yao_spanner.c` |
| C3 | `c3/k/kanj_perkovic_modified_yao_spanner.c3` |
| C++ | `cpp/k/kanj_perkovic_modified_yao_spanner.cpp` |
| Elisa | `elisa/k/kanj_perkovic_modified_yao_spanner.elisa` |
| Mojo | `mojo/k/kanj_perkovic_modified_yao_spanner.mojo` |
| Nim | `nim/k/kanj_perkovic_modified_yao_spanner.nim` |
| Odin | `odin/k/kanj_perkovic_modified_yao_spanner.odin` |
| Rust | `rust/k/kanj_perkovic_modified_yao_spanner.rs` |
| V | `v/k/kanj_perkovic_modified_yao_spanner.v` |
| Zig | `zig/k/kanj_perkovic_modified_yao_spanner.zig` |

All source and fixture review is static. No programs, tests, scripts, helpers,
checkers, builds, compilers, profilers, or benchmarks were run.
