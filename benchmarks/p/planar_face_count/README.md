# Planar face count

This benchmark counts the faces of a bounded connected planar straight-line
graph, including the unbounded face. The primary implementation sorts each
vertex's incident edges by polar angle, then follows the directed-edge
permutation that keeps one face on a fixed side. Each directed edge belongs to
one orbit, and each orbit is counted once.

## Contract

The exported scalar ABI symbol is `planar_face_count`. Input is the signed
64-bit array `[N,M,(x,y)*N,(u,v)*M]`. There are `1<=N<=16` vertices and
`0<=M<=42` undirected edges, bounded additionally by the simple planar graph
edge limit (`M<=0` for `N=1`, `M<=1` for `N=2`, and `M<=3N-6` otherwise).
Coordinates are distinct integer points in `[-100,100]^2`. Vertex IDs are
zero-based. Edges must be unique, non-looping, and make one connected graph.
The straight-line drawing must have no edge crossings, no vertex in an edge
interior, and no overlapping incident segments; these geometric preconditions
are validated. Input length must be exactly `2+2N+2M` and is at most 118 words.

The result is the number of faces, including the unbounded face. A one-vertex
graph has one face. Malformed or out-of-profile input returns `-1`. The planar
edge bound gives at most 28 faces in this profile.

The structurally independent oracle uses Euler's formula for a connected
planar graph, `F=M-N+2`; it does not sort directions or traverse face
boundaries. The primary validates geometry in `O(M^2)` time, then sorts and
traverses in `O(M log M)` time; it uses `O(N^2+M)` fixed storage. The oracle
uses `O(N+M^2)` time for its independent input checks.

## Distinctness and provenance

[`upward_planarity_angle_assignment`](../../u/upward_planarity_angle_assignment/README.md)
assigns angles in a constrained upward-planarity profile, while
[`st_planar_leftmost_augmenting_flow`](../../s/st_planar_leftmost_augmenting_flow/README.md)
uses a supplied st-planar embedding for flow. Neither enumerates faces from a
planar straight-line graph. Voronoi, Delaunay, half-plane, and polygon
benchmarks produce different geometric results.

The source is [CP-Algorithms, “Finding faces of a planar graph”](https://cp-algorithms.com/geometry/planar.html),
licensed under CC BY-SA 4.0. Only its high-level algorithm description was
used; the contract, test fixtures, oracles, and ten ports are clean-room work.
No source code or task text was copied.

See [`RIGHTS.md`](RIGHTS.md), [`workload.json`](workload.json), the
[primary oracle](../../planar_face_count_oracle.py), the
[Euler-formula oracle](../../planar_face_count_verifier_oracle.py), and the
package-local [static inventory checker](../../check_planar_face_count_package.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/p/planar_face_count.c`](../../../c/p/planar_face_count.c) |
| C3 | [`c3/p/planar_face_count.c3`](../../../c3/p/planar_face_count.c3) |
| C++ | [`cpp/p/planar_face_count.cpp`](../../../cpp/p/planar_face_count.cpp) |
| Elisa | [`elisa/p/planar_face_count.elisa`](../../../elisa/p/planar_face_count.elisa) |
| Mojo | [`mojo/p/planar_face_count.mojo`](../../../mojo/p/planar_face_count.mojo) |
| Nim | [`nim/p/planar_face_count.nim`](../../../nim/p/planar_face_count.nim) |
| Odin | [`odin/p/planar_face_count.odin`](../../../odin/p/planar_face_count.odin) |
| Rust | [`rust/p/planar_face_count.rs`](../../../rust/p/planar_face_count.rs) |
| V | [`v/p/planar_face_count.v`](../../../v/p/planar_face_count.v) |
| Zig | [`zig/p/planar_face_count.zig`](../../../zig/p/planar_face_count.zig) |
