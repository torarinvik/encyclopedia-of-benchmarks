# Directed line and convex hull intersection

Find where a directed infinite line meets the boundary of an already supplied
strictly convex polygon. The result is the pair of boundary edge indices in
the order the directed line encounters them. This is a line query against a
convex hull, not an external-point tangent query, point-membership query,
segment intersection, or hull construction.

## Contract

- ABI: `i64_array_bytes_output`; exported symbol: `line_hull_intersection`.
- Input is `[n,x1,y1,x2,y2,x0,y0,...,x(n-1),y(n-1)]`. The distinct points
  `(x1,y1)` and `(x2,y2)` define the directed line from the first to the
  second. `3<=n<=16`; all coordinates are integers in `[-50,50]`.
- Polygon vertices are distinct and strictly convex, in counterclockwise
  cyclic order. Any starting vertex is accepted. Strict convexity is checked
  by requiring each non-edge vertex to lie strictly left of every directed
  edge. The maximum valid frame has 37 signed 64-bit values; 38 are parsed
  only to reject trailing input. Invalid input returns `-1`.
- Success writes two signed 64-bit little-endian edge indices and returns 16.
  `[-1,-1]` means no hit. `[i,-1]` means a single corner touch at vertex `i`;
  its outgoing edge index is used. `[i,i]` means overlap with side `(i,i+1)`.
  `[i,j]` means two intersections on edges `(i,i+1)` and `(j,j+1)`, ordered
  by increasing parameter along the directed line. If an intersection is a
  polygon vertex, that vertex's outgoing edge index represents it.
- After validating the complete input, a null output pointer or capacity
  below 16 returns `-2` and writes nothing. Invalid input takes precedence.

The primary uses the circular polar ordering of the strictly convex polygon's
edge directions. A binary search locates its rotation and the support edges
for both line normals; two more binary searches locate the crossings on the
monotone polygon chains. Its query work is `O(log n)` after the bounded
`O(n^2)` input validation. The independent reference scans all polygon edges,
forms exact rational line parameters, and sorts the at most two hits along the
directed line.

## Local distinction and sources

[`external_point_tangents_convex_polygon`](../e/external_point_tangents_convex_polygon/README.md)
returns tangent vertices for an external point. This package returns boundary
intersection edges for an infinite directed line. The local convex-polygon
membership and segment-intersection packages also have different outputs and
query models.

- Bernard Chazelle and David P. Dobkin, [“Intersection of Convex Objects in
  Two and Three Dimensions”](https://www.cs.princeton.edu/~chazelle/pubs/IntersectConvexObjects2-3Dim.pdf),
  *Journal of the ACM* 34(1), 1987. It gives an `O(log n)` line/convex-polygon
  intersection method based on bimodal signed distances and binary searches
  on the two boundary chains.
- Kurt Mehlhorn, [“Convex Polygons”](https://people.mpi-inf.mpg.de/~mehlhorn/ftp/EATCSmonograph/chapter8.pdf),
  section 8.1, describes logarithmic line intersection for cyclically stored
  convex polygons.
- KACTL's [geometry chapter index](https://github.com/kth-competitive-programming/kactl/blob/main/content/geometry/chapter.tex)
  supplied the discovery title `LineHullIntersection.h`. Its public
  [header description](https://github.com/kth-competitive-programming/kactl/blob/main/content/geometry/LineHullIntersection.h)
  confirmed the edge-pair result and its corner, overlap, and no-hit cases.
  Discovery metadata only; no implementation code, tests, examples, or prose
  were copied.

[`workload.json`](workload.json) covers two-edge crossings, vertex crossings,
corner tangency, collinear side overlap, no hit, arbitrary cyclic starts,
invalid polygons, malformed frames, and output-buffer errors. The two
independently structured source references are `primary_oracle.py` and
`independent_oracle.py`; `check_inventory.py` and `verify_workload.py` are
static-only utilities and have not been run.

| Language | Source |
| --- | --- |
| C | [`c/l/line_hull_intersection.c`](../../../c/l/line_hull_intersection.c) |
| C3 | [`c3/l/line_hull_intersection.c3`](../../../c3/l/line_hull_intersection.c3) |
| C++ | [`cpp/l/line_hull_intersection.cpp`](../../../cpp/l/line_hull_intersection.cpp) |
| Elisa | [`elisa/l/line_hull_intersection.elisa`](../../../elisa/l/line_hull_intersection.elisa) |
| Mojo | [`mojo/l/line_hull_intersection.mojo`](../../../mojo/l/line_hull_intersection.mojo) |
| Nim | [`nim/l/line_hull_intersection.nim`](../../../nim/l/line_hull_intersection.nim) |
| Odin | [`odin/l/line_hull_intersection.odin`](../../../odin/l/line_hull_intersection.odin) |
| Rust | [`rust/l/line_hull_intersection.rs`](../../../rust/l/line_hull_intersection.rs) |
| V | [`v/l/line_hull_intersection.v`](../../../v/l/line_hull_intersection.v) |
| Zig | [`zig/l/line_hull_intersection.zig`](../../../zig/l/line_hull_intersection.zig) |
