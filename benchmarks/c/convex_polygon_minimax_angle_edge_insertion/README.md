# Convex-polygon min-max-angle edge insertion

This bounded profile applies the min-max-angle objective to a convex triangle or
quadrilateral. It starts from a fan triangulation, selects a largest-angle
triangle, and tests the edge insertion that crosses the opposite edge. On four
vertices there are only two triangulations, so the search can test the complete
candidate set and stop after the one possible insertion.

## Contract

The scalar symbol is `convex_polygon_minimax_angle_edge_insertion`. Input is
`[N, x0, y0, ..., x(N-1), y(N-1)]`, with `3 <= N <= 4`, integer coordinates in
`[-16,16]`, and vertices in strict convex boundary order (either orientation).
No three points may be collinear. Malformed lengths, duplicate points,
nonconvex order, collinear triples, and out-of-range coordinates return `-1`.
The maximum valid input has 9 i64 words; the maximum parseable frame is 10.

The result is the 1-based rank of the optimum maximum angle among the distinct
angles induced by every three-point subset of the input. Equal angle measures
share a rank. Exact dot-product comparisons avoid floating point and trigonometry.

The primary follows the min-max edge-insertion outline in the paper. For tied
largest angles it checks each occurrence in triangle order and then vertex
order, so a non-crossing occurrence cannot hide a valid insertion at another
tied angle. It inserts the unique remaining vertex only if the new diagonal
properly crosses the current opposite edge; it accepts the replacement only
when its maximum angle is strictly smaller. Equal objectives keep the starting
fan. The independent reference enumerates both quadrilateral triangulations
directly.

This package does not claim to reproduce the paper's general-point-set
O(n² log n) implementation. It profiles the bounded convex triangle and
quadrilateral edge-insertion cases only.

This objective differs from Delaunay triangulation's max-min-angle objective.
The `minmax-vs-delaunay-diagonal` workload case has min-max-angle optimum rank
11 at diagonal 1-3, while the max-min-angle choice is diagonal 0-2.

## Provenance and rights

The source chapter is Tiow-Seng Tan, [“Optimal Triangulation,” *Encyclopedia of
Algorithms*](https://doi.org/10.1007/978-1-4939-2864-4_715). The algorithm
description is based on Edelsbrunner, Tan, and Waupotitsch, [“An O(n² log n)
Time Algorithm for the Minmax Angle Triangulation,” SIAM Journal on Scientific
Computing 13(4), 994–1008 (1992)](https://doi.org/10.1137/0913058); an author copy
is listed on [Tiow-Seng Tan’s publication page](https://www.comp.nus.edu.sg/~tants/).
The publications remain copyrighted. This package contains clean-room
implementations of the bounded algorithm profile and objective; it does not
reproduce their source code, text, or figures. See [RIGHTS.md](RIGHTS.md),
[workload.json](workload.json), the [primary reference](../../convex_polygon_minimax_angle_edge_insertion_oracle.py),
the [independent reference](../../convex_polygon_minimax_angle_edge_insertion_verifier_oracle.py),
and the [static inventory](../../check_convex_polygon_minimax_angle_edge_insertion_package.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/c/convex_polygon_minimax_angle_edge_insertion.c`](../../../c/c/convex_polygon_minimax_angle_edge_insertion.c) |
| C3 | [`c3/c/convex_polygon_minimax_angle_edge_insertion.c3`](../../../c3/c/convex_polygon_minimax_angle_edge_insertion.c3) |
| C++ | [`cpp/c/convex_polygon_minimax_angle_edge_insertion.cpp`](../../../cpp/c/convex_polygon_minimax_angle_edge_insertion.cpp) |
| Elisa | [`elisa/c/convex_polygon_minimax_angle_edge_insertion.elisa`](../../../elisa/c/convex_polygon_minimax_angle_edge_insertion.elisa) |
| Mojo | [`mojo/c/convex_polygon_minimax_angle_edge_insertion.mojo`](../../../mojo/c/convex_polygon_minimax_angle_edge_insertion.mojo) |
| Nim | [`nim/c/convex_polygon_minimax_angle_edge_insertion.nim`](../../../nim/c/convex_polygon_minimax_angle_edge_insertion.nim) |
| Odin | [`odin/c/convex_polygon_minimax_angle_edge_insertion.odin`](../../../odin/c/convex_polygon_minimax_angle_edge_insertion.odin) |
| Rust | [`rust/c/convex_polygon_minimax_angle_edge_insertion.rs`](../../../rust/c/convex_polygon_minimax_angle_edge_insertion.rs) |
| V | [`v/c/convex_polygon_minimax_angle_edge_insertion.v`](../../../v/c/convex_polygon_minimax_angle_edge_insertion.v) |
| Zig | [`zig/c/convex_polygon_minimax_angle_edge_insertion.zig`](../../../zig/c/convex_polygon_minimax_angle_edge_insertion.zig) |
