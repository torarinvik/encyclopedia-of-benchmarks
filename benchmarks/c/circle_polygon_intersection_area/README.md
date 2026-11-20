# Circle–polygon intersection area

This benchmark computes the area shared by a circle and a strictly convex
polygon. The primary ports use oriented edge contributions: each polygon edge
contributes either a circular sector or a combination of two sectors and a
triangle after the edge is clipped to the circle.

## Contract

The ABI is `i64_array_float64`, with symbol `circle_polygon_intersection_area`.
Input is `[N, cx, cy, r, x0, y0, ..., x(N-1), y(N-1)]`. There must be between
3 and 16 vertices, and the exact input length is `4 + 2*N`. Circle center and
vertex coordinates are signed integers in `[-32, 32]`; the integer radius is
in `[1, 32]`. Vertices must be distinct and in strictly convex,
counterclockwise order. The circle center must lie strictly inside the
polygon. Invalid or null input returns `-1e300`.

The binary64 result is the nonnegative area of the intersection. It is at most
the smaller of the polygon area and `pi*r*r`, and therefore at most
`1024*pi` (about 3216.991). Workloads use absolute tolerance `1e-9` and
relative tolerance `1e-12`. The largest valid input has 36 integers; a 37th
integer is accepted only so the implementation can reject trailing data.

## Algorithm and distinction

For each directed edge, the primary solves the edge-line/circle quadratic.
When the segment does not cross the disk, the edge contributes its signed
sector. When it crosses, the segment is split at its circle intersections;
the middle chord contributes a triangle and the two exterior edge portions
contribute circular sectors. Summing the oriented pieces and halving gives the
intersection area. Strict counterclockwise convexity and an interior center
make every edge's angular contribution well-defined. Geometry takes `O(N)`;
the strict-convexity and center-containment validation checks all vertices
against all edges in `O(N^2)`. Fixed arrays use `O(N)` auxiliary space.

The independent Python oracle uses polar integration instead. For each ray
from the center it finds the polygon boundary distance, clips that distance
against the circle radius, and adaptively integrates half the squared clipped
radius. It splits integration intervals at vertex directions and
edge-circle-intersection directions. This is structurally separate from the
edge-sector sum.

The repository already has circle-line and circle-circle intersection
benchmarks, plus polygon containment and polygon triangulation. Those answer
different predicates or construct different geometry; none computes the
circle/polygon common area.

## Source and rights

KACTL's geometry index imports `CirclePolygonIntersection.h`, whose stated
operation is the area of intersection of a circle and a counterclockwise
polygon in linear time. Its source declares CC0. This package uses the
algorithmic idea only and contains independently authored implementations,
fixtures, and documentation; no KACTL code, comments, prose, or test data are
copied. See [`RIGHTS.md`](RIGHTS.md).

- [KACTL geometry chapter index](https://raw.githubusercontent.com/kth-competitive-programming/kactl/main/content/geometry/chapter.tex)
- [KACTL CirclePolygonIntersection.h](https://github.com/kth-competitive-programming/kactl/blob/main/content/geometry/CirclePolygonIntersection.h)

[`workload.json`](workload.json) contains hand-derived geometry fixtures and
malformed frames. [`primary_oracle.py`](primary_oracle.py) follows the
edge-sector method; [`independent_oracle.py`](independent_oracle.py) uses
adaptive polar integration. [`inventory.json`](inventory.json) records the
static ten-port inventory and source identity; `check_inventory.py` provides
a static file-and-metadata review and has not been run.

| Language | Source |
|---|---|
| C | [`c/circle_polygon_intersection_area.c`](../../../c/circle_polygon_intersection_area.c) |
| C3 | [`c3/circle_polygon_intersection_area.c3`](../../../c3/circle_polygon_intersection_area.c3) |
| C++ | [`cpp/circle_polygon_intersection_area.cpp`](../../../cpp/circle_polygon_intersection_area.cpp) |
| Elisa | [`elisa/circle_polygon_intersection_area.elisa`](../../../elisa/circle_polygon_intersection_area.elisa) |
| Mojo | [`mojo/circle_polygon_intersection_area.mojo`](../../../mojo/circle_polygon_intersection_area.mojo) |
| Nim | [`nim/circle_polygon_intersection_area.nim`](../../../nim/circle_polygon_intersection_area.nim) |
| Odin | [`odin/circle_polygon_intersection_area.odin`](../../../odin/circle_polygon_intersection_area.odin) |
| Rust | [`rust/circle_polygon_intersection_area.rs`](../../../rust/circle_polygon_intersection_area.rs) |
| V | [`v/circle_polygon_intersection_area.v`](../../../v/circle_polygon_intersection_area.v) |
| Zig | [`zig/circle_polygon_intersection_area.zig`](../../../zig/circle_polygon_intersection_area.zig) |

The `i64_array_float64` recorder and verifier register all ten ports with the
bounded workload and the independent polar-integration reference. This
integration was written statically; no programs or validation tools were run.
