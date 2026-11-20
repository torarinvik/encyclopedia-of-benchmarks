# Triangle union area by exact vertical decomposition

This benchmark computes the exact area of the union of one to three nondegenerate triangles. It is a clean-room bounded adaptation of the vertical-stripe method described by [CP-Algorithms](https://cp-algorithms.com/geometry/vertical_decomposition.html), whose article is available under CC BY-SA 4.0. No article code or prose is reproduced.

## Input and output

The `i64_array_bytes_output` symbol is `triangle_union_area_vertical_decomposition`. Input is `[n,(x1,y1,x2,y2,x3,y3)*n]`, with `1<=n<=3` and each integer coordinate in `[-1,1]`. Each triangle must have three distinct, noncollinear vertices. Either winding is accepted. Vertical sides, overlaps, containment, shared endpoints, shared or coincident sides, and endpoint intersections are valid. Coincident segment ties use stable input segment IDs.

The result is exactly 16 bytes: the reduced nonnegative area numerator followed by its positive denominator, each as a little-endian signed 64-bit word. Invalid framing, coordinates, or degenerate triangles return `-1`. A valid input with null output or capacity below 16 returns `-2`; validation has precedence and errors do not write output.

## Exact method and arithmetic bound

The primary reference and ports collect rational x-events at triangle vertices and at pairwise side intersections. After exact sorting and deduplication, each open stripe has fixed side order. At its midpoint, each triangle contributes a vertical interval; intervals are merged with stable segment-index ties. The union components are integrated as exact trapezoids between the stripe boundaries.

With coordinates in `[-1,1]`, each supporting-line intersection denominator is at most 8, so event x denominators divide 840. Side heights at events have denominators dividing 1,680. Every trapezoid area denominator divides 2,822,400. The union lies within the square `[-1,1]^2`, so its area is at most 4 and the reduced numerator is at most 11,289,600. Reduced rational intermediates and the output pair therefore fit signed 64-bit words. The straightforward ports check each of O(S²) intersection candidates against the event list and insertion-sort up to O(S²) events, so their conservative worst-case work is O(S⁴), with S=3n<=9. The package checker and workload pin representative values and exact fractions.

The independent reference uses inclusion-exclusion over triangles, with exact convex half-plane clipping for pair and triple intersections. It does not use the stripe/event algorithm.

## Ports

| Language | Source |
|---|---|
| C | [c/t/triangle_union_area_vertical_decomposition.c](../../../c/t/triangle_union_area_vertical_decomposition.c) |
| C3 | [c3/t/triangle_union_area_vertical_decomposition.c3](../../../c3/t/triangle_union_area_vertical_decomposition.c3) |
| C++ | [cpp/t/triangle_union_area_vertical_decomposition.cpp](../../../cpp/t/triangle_union_area_vertical_decomposition.cpp) |
| Elisa | [elisa/t/triangle_union_area_vertical_decomposition.elisa](../../../elisa/t/triangle_union_area_vertical_decomposition.elisa) |
| Mojo | [mojo/t/triangle_union_area_vertical_decomposition.mojo](../../../mojo/t/triangle_union_area_vertical_decomposition.mojo) |
| Nim | [nim/t/triangle_union_area_vertical_decomposition.nim](../../../nim/t/triangle_union_area_vertical_decomposition.nim) |
| Odin | [odin/t/triangle_union_area_vertical_decomposition.odin](../../../odin/t/triangle_union_area_vertical_decomposition.odin) |
| Rust | [rust/t/triangle_union_area_vertical_decomposition.rs](../../../rust/t/triangle_union_area_vertical_decomposition.rs) |
| V | [v/t/triangle_union_area_vertical_decomposition.v](../../../v/t/triangle_union_area_vertical_decomposition.v) |
| Zig | [zig/t/triangle_union_area_vertical_decomposition.zig](../../../zig/t/triangle_union_area_vertical_decomposition.zig) |
