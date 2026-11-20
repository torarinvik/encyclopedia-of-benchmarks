# Thomassen convex-drawing extendibility

This package tests whether a specified convex polygon is extendible for a
bounded simple 2-connected plane graph. It returns the theorem's yes/no result;
it does not construct coordinates or a drawing.

The input is
`[n,m,f,outer_face,side_count,(u,v)*m,(face_length,face_vertices...)*f,apex_positions*side_count]`.
Vertices use IDs `0..n-1`; each undirected edge has `u<v`, and edges are in
lexicographic order. Each listed face is a simple cyclic vertex walk. The
selected face is the outer boundary. Apex positions are distinct, strictly
increasing positions in that boundary walk; consecutive apices, including the
last-to-first pair, delimit the side paths. Each path includes both endpoint
vertices.

The profile requires a connected graph that stays connected after deleting
any one vertex, `n-m+f=2`, and every directed edge use exactly once in each
orientation. Each vertex link must be one connected cycle: its nodes are the
incident neighbors, and each face corner adds a link edge between its previous
and next boundary neighbors. Every link node has degree two; graph-degree-two
vertices use two parallel link edges. These local checks reject pinched face
systems that satisfy edge-dart counts and Euler's relation but are not a sphere
embedding. Bounds are `3<=n<=8`, `n<=m<=min(18,3*n-6)`, `2<=f<=12`, and
`3<=side_count<=n`. The largest valid frame is 92 signed-i64 words; 93 words
are accepted by the parser limit so a trailing-word frame can be classified as
invalid. The scalar result is `1` when all three conditions below hold, `0`
when at least one fails, and `-1` for malformed input.

The conditions are:

1. Every nonouter vertex of degree at least three has three internally
   vertex-disjoint paths to three distinct outer-boundary vertices.
2. No connected component of the graph induced by inner vertices has all its
   outer neighbors on a single side path, and no nonouter edge has both
   endpoints on one side path.
3. Every cycle that uses no outer-boundary edge contains at least three
   vertices whose full graph degree is at least three.

The primary reference checks condition one with vertex-split unit-capacity
max-flow, checks side contacts by component traversal, and checks condition
three with a subset dynamic program that minimizes the count of degree-at-least
three vertices on each simple cycle. The independent reference enumerates
simple paths for condition one and simple cycles with DFS for condition three.
The graph and all searches are bounded by eight vertices. The maximum flow
network has 18 nodes; cycle-state storage is at most `256*8` entries.

## Source and distinction

Thomassen, “Convex Graph Drawing,” *Encyclopedia of Algorithms*, Chapter 652,
[DOI 10.1007/978-1-4939-2864-4_652](https://doi.org/10.1007/978-1-4939-2864-4_652),
Theorem 1. The package implements the theorem's three extendibility tests for
a supplied embedding and side-path partition. This output is a decision bit,
not a canonical ordering, Schnyder realizer, convex drawing, or coordinate
construction.

See [`RIGHTS.md`](RIGHTS.md) for provenance and reuse notes.

## Ports

| Language | Source |
|---|---|
| C | `c/t/thomassen_convex_drawing_extendibility.c` |
| C3 | `c3/t/thomassen_convex_drawing_extendibility.c3` |
| C++ | `cpp/t/thomassen_convex_drawing_extendibility.cpp` |
| Elisa | `elisa/t/thomassen_convex_drawing_extendibility.elisa` |
| Mojo | `mojo/t/thomassen_convex_drawing_extendibility.mojo` |
| Nim | `nim/t/thomassen_convex_drawing_extendibility.nim` |
| Odin | `odin/t/thomassen_convex_drawing_extendibility.odin` |
| Rust | `rust/t/thomassen_convex_drawing_extendibility.rs` |
| V | `v/t/thomassen_convex_drawing_extendibility.v` |
| Zig | `zig/t/thomassen_convex_drawing_extendibility.zig` |

`workload.json` pins a positive triangle and triangulation, one failure fixture
for each theorem condition, a maximum-size triangulation, malformed plane
embeddings and frames, and null input. `check_inventory.py` statically checks
the metadata, fixture/reference agreement, and all ten source paths; it is not
run as part of writing this package.
