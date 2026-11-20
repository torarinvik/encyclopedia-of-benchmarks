# Max-min triangle-height triangulation

This benchmark finds the triangulation of a small convex polygon whose least
triangle altitude is as large as possible. It uses exact rational arithmetic
and returns the squared optimum, packed into a scalar.

## Contract

The ABI is `i64_array_scalar` and the exported symbol is
`max_min_triangle_height_triangulation`. Input is
`[n,x0,y0,...,x(n-1),y(n-1)]`. There must be 3 to 5 distinct vertices with
coordinates in `[-8,8]`, listed in strict counterclockwise boundary order.
The polygon must be strictly convex and no three vertices may be collinear.
The frame length is exactly `1+2*n`; lengths up to 12 are parsed so a
trailing-word frame can be rejected. Invalid and null input returns `-1`.

For a triangle, the altitude to a side of squared length `d2` has square
`area2*area2/d2`, where `area2` is the absolute doubled area. The triangle
height is its least altitude, so its squared height is the minimum of those
three exact fractions. A triangulation's score is its least triangle score;
the algorithm maximizes that score. Reduced `num/den` is encoded as
`num*513+den`. The input bounds keep the numerator at most 262144 and the
denominator at most 512, so all output values fit the declared bound.

## Algorithm

The primary implementation starts from a fan at vertex zero. It scans absent
diagonals in lexicographic endpoint order. For each diagonal, dynamic
programming finds the best triangulations of the two cyclic subpolygons it
separates; the first strict improvement is inserted and the scan restarts.
Subpolygon and whole-triangulation objectives compare `(minimum squared
height, number of triangles attaining that minimum)`. The second value only
breaks ties in the primary objective and does not change the reported
max-min height. DP split ties choose the smallest split index.

Every accepted insertion strictly increases this ordered pair. With at most
five polygon vertices there are at most ten distinct triangles, hence at
most ten possible minimum scores; each score can be paired with a count from
one through three. Thus at most 30 ordered states exist and the bounded
implementation's 30-insertion guard cannot be exceeded. The independent
oracle recursively enumerates every triangulation (at most five for this
bound) and scores them directly.

This is a geometric triangulation objective, distinct from minimum-weight
triangulation, minimum-maximum angle triangulation, and the local
`convex_polygon_minimax_angle_edge_insertion` package.

## Provenance and ports

The objective is summarized in Tiow-Seng Tan's
[“Optimal Triangulation” chapter in the Encyclopedia of Algorithms](https://doi.org/10.1007/978-1-4939-2864-4_715).
The edge-insertion paradigm is described by Bern, Edelsbrunner, Eppstein,
Mitchell, and Tan in [“Edge insertion for optimal triangulations”](https://doi.org/10.1007/BF02573962);
Tan's [author-hosted paper](https://www.comp.nus.edu.sg/~tants/Paper/eis.pdf)
is also included as an algorithm-ideas source. The code is independently
written from those descriptions; no source code is copied. See
[`RIGHTS.md`](RIGHTS.md).

| Language | Source |
| --- | --- |
| C | [c/m/max_min_triangle_height_triangulation.c](../../../c/m/max_min_triangle_height_triangulation.c) |
| C3 | [c3/m/max_min_triangle_height_triangulation.c3](../../../c3/m/max_min_triangle_height_triangulation.c3) |
| C++ | [cpp/m/max_min_triangle_height_triangulation.cpp](../../../cpp/m/max_min_triangle_height_triangulation.cpp) |
| Elisa | [elisa/m/max_min_triangle_height_triangulation.elisa](../../../elisa/m/max_min_triangle_height_triangulation.elisa) |
| Mojo | [mojo/m/max_min_triangle_height_triangulation.mojo](../../../mojo/m/max_min_triangle_height_triangulation.mojo) |
| Nim | [nim/m/max_min_triangle_height_triangulation.nim](../../../nim/m/max_min_triangle_height_triangulation.nim) |
| Odin | [odin/m/max_min_triangle_height_triangulation.odin](../../../odin/m/max_min_triangle_height_triangulation.odin) |
| Rust | [rust/m/max_min_triangle_height_triangulation.rs](../../../rust/m/max_min_triangle_height_triangulation.rs) |
| V | [v/m/max_min_triangle_height_triangulation.v](../../../v/m/max_min_triangle_height_triangulation.v) |
| Zig | [zig/m/max_min_triangle_height_triangulation.zig](../../../zig/m/max_min_triangle_height_triangulation.zig) |

[`workload.json`](workload.json) includes an exact rational triangle, an
equal-score square, a pentagon where edge insertion improves the initial fan,
maximum valid and parseable frames, and invalid geometry/input cases. The
primary and independent reference implementations are kept in this package.
[`verify_workload.py`](verify_workload.py) lists the static package inventory;
it has not been run.

The three hand-derived valid outputs are `144/25 -> 73,897` for the 3-4-5
right triangle, `8/1 -> 4,105` for the square, and `128/17 -> 65,681` for the
pentagon. The pentagon's initial fan has score `32/13`, so the fixture also
checks an accepted insertion.
