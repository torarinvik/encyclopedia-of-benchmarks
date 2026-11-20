# Incremental three-dimensional convex hull volume

This package benchmarks an exact integer incremental hull in three dimensions.
It starts from a tetrahedron, removes outward triangular faces visible from
each new point, and closes the visible region's horizon with new triangles.

## Contract

The ABI is `i64_array_scalar`; the package id and exported symbol are
`incremental_convex_hull_3d`. Input is `[n, x0, y0, z0, ..., x(n-1),
y(n-1), z(n-1)]`, with `4<=n<=6`, coordinates in `[-10,10]`, and exact
length `1+3*n`. Points must be distinct and in general position: no four
points may lie in one plane. This makes the initial four points a valid
tetrahedron and every hull face triangular, avoiding coplanar-facet tie rules.
Invalid or null input returns `-1`.

The scalar result is six times the convex-hull volume. This value is an exact
integer for integer coordinates and avoids floating-point tolerances. The
largest valid frame contains 19 integers; implementations accept one extra
parseable integer to reject trailing data. The scalar result lies in
`0..48000`; 48000 is a safe coordinate-derived upper bound, not necessarily an
attainable value with at most six hull vertices.

## Algorithm and distinction

Every active triangle is oriented so the fixed centroid of the initial
tetrahedron lies on its inward side. A later point sees a face when it lies on
the outward side of that face's exact integer plane. If any faces are visible,
edges appearing once among visible faces form the horizon; those faces are
removed and each horizon edge is joined to the new point. The fixed interior
centroid lets every new triangle be oriented without floating-point normals.
General-position validation checks all point quadruples, so the complete
primary takes `O(n^4)` time; face visibility and the fixed-array horizon
updates take `O(n^3)`. It uses `O(n)` auxiliary space. The independent oracle
enumerates every point triple, keeps supporting planes, and sums their
oriented tetrahedral determinants.

The nearest local hull algorithms operate on planar points. The 3D
[`smallest_enclosing_ball_3d`](../s/smallest_enclosing_ball_3d/README.md)
package computes a ball rather than a polyhedral hull. This benchmark returns
the exact volume of the 3D convex hull.

## Source and ports

The source audit found `3dHull.h` in KACTL's geometry content index. The
implementation idea is cross-referenced with Barber, Dobkin, and Huhdanpaa's
[Quickhull paper](https://doi.org/10.1145/235815.235821), which describes
incremental convex-hull construction. Only the algorithm idea is used; no
KACTL or paper code or prose is copied. See [`RIGHTS.md`](RIGHTS.md).

| Language | Port |
|---|---|
| C | [`c/i/incremental_convex_hull_3d.c`](../../../c/i/incremental_convex_hull_3d.c) |
| C3 | [`c3/i/incremental_convex_hull_3d.c3`](../../../c3/i/incremental_convex_hull_3d.c3) |
| C++ | [`cpp/i/incremental_convex_hull_3d.cpp`](../../../cpp/i/incremental_convex_hull_3d.cpp) |
| Elisa | [`elisa/i/incremental_convex_hull_3d.elisa`](../../../elisa/i/incremental_convex_hull_3d.elisa) |
| Mojo | [`mojo/i/incremental_convex_hull_3d.mojo`](../../../mojo/i/incremental_convex_hull_3d.mojo) |
| Nim | [`nim/i/incremental_convex_hull_3d.nim`](../../../nim/i/incremental_convex_hull_3d.nim) |
| Odin | [`odin/i/incremental_convex_hull_3d.odin`](../../../odin/i/incremental_convex_hull_3d.odin) |
| Rust | [`rust/i/incremental_convex_hull_3d.rs`](../../../rust/i/incremental_convex_hull_3d.rs) |
| V | [`v/i/incremental_convex_hull_3d.v`](../../../v/i/incremental_convex_hull_3d.v) |
| Zig | [`zig/i/incremental_convex_hull_3d.zig`](../../../zig/i/incremental_convex_hull_3d.zig) |

[`workload.json`](workload.json) covers a tetrahedron, a point outside the
initial hull, an interior point, the maximum frame, and malformed inputs.
[`verify_workload.py`](verify_workload.py) provides static fixture and source
inventory review; it has not been run as part of this audit.
