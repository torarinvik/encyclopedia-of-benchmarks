# Weiler–Atherton polygon intersection

This bounded benchmark computes the exact intersection boundary of two simple
polygons. The primary uses Weiler–Atherton's interleaved boundary lists and
entry/exit traversal. It can emit multiple disconnected rings, including hole
boundaries when the intersection has holes.

## Contract

- ABI: `i64_array_bytes_output`; symbol:
  `weiler_atherton_polygon_intersection`.
- Input is `[n_a,n_b,(x,y)*n_a,(x,y)*n_b]`. Each polygon has 3–6 vertices,
  integer coordinates in `[-16,16]`, and is listed counterclockwise.
- Each polygon must be simple, have distinct vertices, and have no collinear
  consecutive edges. Between polygons, every boundary intersection must be a
  proper crossing in the interior of both edges. Touching, endpoint hits,
  shared or overlapping edges, and collinear consecutive edges are invalid.
  Collinear edge pairs with disjoint segments are allowed because they do not
  intersect.
- Input bounds are 26 valid and 27 parseable i64 words. Invalid or null input
  returns `-1`. Null or short output returns `-2` after full input validation
  and writes no bytes.
- Output is `[ring_count,(vertex_count,(x_num,x_den,y_num,y_den)*)*]`, encoded
  as little-endian signed i64 words. Coordinate fractions are reduced with
  positive denominators. Each directed ring has the intersection interior on
  its left, is rotated to begin at its lexicographically least rational point,
  and the rings are sorted lexicographically by their point sequences. An
  empty intersection is `[0]`.
- The output cap is 1,680 bytes. At most 36 proper edge crossings can occur;
  together with the 12 original vertices, the boundary has at most 48
  vertices. With at least three vertices per nondegenerate ring, the serialized
  count is at most `1 + 16 + 4*48 = 209` words (1,672 bytes), within the cap.
  Workspace is 65,536 bytes, excluding caller-owned buffers.

The primary inserts each proper crossing into both cyclic edge lists, sorted
by edge index and exact segment parameter. Local inside/outside transitions
label entry and exit crossings. Starting at each unvisited entry in polygon A
list order, it follows A to an exit, switches to the paired crossing in B,
and alternates until it returns to the start. If there are no crossings, an
exact point-in-polygon test returns the contained polygon or the empty set.

The independent reference does not walk linked crossing lists. It splits
every directed input edge at its crossings, keeps fragments whose exact
rational midpoint lies inside the other polygon, and joins the directed
fragments by endpoint equality. Both outputs are canonicalized using exact
rational comparisons.

The local [`cohen_sutherland`](../../c/cohen_sutherland/README.md) and
[`liang_barsky`](../../l/liang_barsky/README.md) profiles clip line segments to
rectangles. [`half_plane_intersection_incremental_clipping`](../../h/half_plane_intersection_incremental_clipping/README.md)
successively clips one convex region against half-planes. Those kernels do not
build the intersection rings of two possibly concave polygon boundaries.

## Sources and rights

The pinned RosettaCodeData [score-13 popular-task index](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks)
provides discovery only. The primary method source is Weiler and Atherton,
“Hidden Surface Removal Using Polygon Area Sorting,” SIGGRAPH 1977,
[DOI 10.1145/563858.563896](https://doi.org/10.1145/563858.563896), which
describes a general polygon clipper based on interleaved boundary lists. The
independent arrangement reference is grounded in the standard simple-polygon
intersection reduction to edge crossings and fragment classification, as
summarized in *Handbook of Discrete and Computational Geometry*, Chapter 42.
See [RIGHTS.md](RIGHTS.md).

The workload includes disjoint and contained polygons, integer and rational
crossings, maximum-length input, malformed geometry, null buffers, and short
capacity. Ten language ports and the static package files are listed in
[INVENTORY.md](INVENTORY.md). Workload/inventory helpers are authored only; none
has been run.

| Language | Source |
|---|---|
| C | [c/w/weiler_atherton_polygon_intersection.c](../../../c/w/weiler_atherton_polygon_intersection.c) |
| C3 | [c3/w/weiler_atherton_polygon_intersection.c3](../../../c3/w/weiler_atherton_polygon_intersection.c3) |
| C++ | [cpp/w/weiler_atherton_polygon_intersection.cpp](../../../cpp/w/weiler_atherton_polygon_intersection.cpp) |
| Elisa | [elisa/w/weiler_atherton_polygon_intersection.elisa](../../../elisa/w/weiler_atherton_polygon_intersection.elisa) |
| Mojo | [mojo/w/weiler_atherton_polygon_intersection.mojo](../../../mojo/w/weiler_atherton_polygon_intersection.mojo) |
| Nim | [nim/w/weiler_atherton_polygon_intersection.nim](../../../nim/w/weiler_atherton_polygon_intersection.nim) |
| Odin | [odin/w/weiler_atherton_polygon_intersection.odin](../../../odin/w/weiler_atherton_polygon_intersection.odin) |
| Rust | [rust/w/weiler_atherton_polygon_intersection.rs](../../../rust/w/weiler_atherton_polygon_intersection.rs) |
| V | [v/w/weiler_atherton_polygon_intersection.v](../../../v/w/weiler_atherton_polygon_intersection.v) |
| Zig | [zig/w/weiler_atherton_polygon_intersection.zig](../../../zig/w/weiler_atherton_polygon_intersection.zig) |
