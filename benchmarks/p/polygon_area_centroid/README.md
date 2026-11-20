# Polygon area centroid

Compute the uniform-area centroid of a strictly convex polygon from its
ordered vertices. This is the centroid of the filled polygon region, not the
arithmetic mean of its vertices or a mass-weighted center of separate points.

## Contract

- ABI: `i64_array_bytes_output`; exported symbol:
  `polygon_area_centroid`.
- Input is exactly `[n,x0,y0,...,x(n-1),y(n-1)]`, with `3<=n<=16` and
  integer coordinates in `[-50,50]`. Vertices must be distinct and supplied
  in strict convex cyclic order, clockwise or counterclockwise. Validation
  requires every non-edge vertex to lie strictly on the same orientation-
  consistent side of each directed edge.
- The maximum valid frame is 33 signed 64-bit values; 34 values are
  parseable to reject trailing input. A degenerate, non-convex, malformed, or
  out-of-range input returns `-1`.
- Let `cross_i=x_i*y_(i+1)-x_(i+1)*y_i` and
  `S=sum(cross_i)`. Then the exact centroid is
  `Cx=sum((x_i+x_(i+1))*cross_i)/(3*S)` and
  `Cy=sum((y_i+y_(i+1))*cross_i)/(3*S)`. Return both coordinates multiplied
  by 1,000,000 and rounded to nearest integer, with exact ties away from
  zero.
- On success, write two signed 64-bit little-endian values `[Cx_micro,
  Cy_micro]` and return 16. After full input validation, a null output pointer
  or capacity below 16 returns `-2` and writes nothing. Invalid input takes
  precedence over output-buffer errors.

The primary reference accumulates signed edge cross sums. The independent
reference triangulates the convex polygon from its first vertex and area-
weights the triangle centroids. Both use exact integer rational arithmetic
for the final micro-unit rounding. Input validation is `O(n^2)`; centroid
calculation is `O(n)`.

## Distinction from local geometry profiles

[`center_of_mass`](../c/center_of_mass/README.md) computes a mass-weighted
average of discrete particle coordinates. [`area_of_polygon`](../a/area_of_polygon/README.md)
returns area but no centroid. This package computes the area centroid of a
filled polygon, which can differ from its vertex mean and from a particle
center of mass.

## Sources and discovery

- Francis E. Greulich, [“Accurate Polygon Centroid Computation Using ARC/INFO GIS”](https://doi.org/10.1061/(ASCE)0887-3801(1995)9:1(88)), *Journal of Computing in Civil Engineering* 9(1), 1995. The [author-hosted paper](https://faculty.washington.edu/greulich/Documents/Centroid.pdf) gives the signed-area centroid formula.
- The University of Melbourne's [computational geometry notes](https://tomkom.pages.gitlab.unimelb.edu.au/spatialdatamanagement/21_geometrical_analysis.html) independently describes the simple-polygon centroid and its shoelace formula.
- KACTL's [geometry chapter index](https://github.com/kth-competitive-programming/kactl/blob/main/content/geometry/chapter.tex) supplied the discovery title `PolygonCenter.h`; its public [header description](https://github.com/kth-competitive-programming/kactl/blob/main/content/geometry/PolygonCenter.h) confirmed the operation. No implementation code or prose was copied.

## Workload and ports

[`workload.json`](workload.json) includes triangles, rectangles, an asymmetric
trapezoid, reversed winding, the maximum vertex count, malformed and
non-convex orders, null output, and capacity errors. The primary and
independent source references are `primary_oracle.py` and
`independent_oracle.py`. `check_inventory.py` and `verify_workload.py` are
source-only static utilities and have not been run. The shared byte-output
runner uses the shoelace reference; its verifier uses the independent fan
triangulation reference.

| Language | Source |
| --- | --- |
| C | [`c/p/polygon_area_centroid.c`](../../../c/p/polygon_area_centroid.c) |
| C3 | [`c3/p/polygon_area_centroid.c3`](../../../c3/p/polygon_area_centroid.c3) |
| C++ | [`cpp/p/polygon_area_centroid.cpp`](../../../cpp/p/polygon_area_centroid.cpp) |
| Elisa | [`elisa/p/polygon_area_centroid.elisa`](../../../elisa/p/polygon_area_centroid.elisa) |
| Mojo | [`mojo/p/polygon_area_centroid.mojo`](../../../mojo/p/polygon_area_centroid.mojo) |
| Nim | [`nim/p/polygon_area_centroid.nim`](../../../nim/p/polygon_area_centroid.nim) |
| Odin | [`odin/p/polygon_area_centroid.odin`](../../../odin/p/polygon_area_centroid.odin) |
| Rust | [`rust/p/polygon_area_centroid.rs`](../../../rust/p/polygon_area_centroid.rs) |
| V | [`v/p/polygon_area_centroid.v`](../../../v/p/polygon_area_centroid.v) |
| Zig | [`zig/p/polygon_area_centroid.zig`](../../../zig/p/polygon_area_centroid.zig) |
