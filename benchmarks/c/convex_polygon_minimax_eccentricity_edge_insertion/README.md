# Convex-polygon min-max eccentricity edge insertion

This bounded profile minimizes the maximum eccentricity of a triangle in a
triangulation of a strictly convex polygon. A triangle's eccentricity is the
distance from its circumcenter to the closest point in the closed triangle.
It is zero when the circumcenter lies inside or on the triangle. This measure
differs from the maximum angle, minimum altitude, and lifted-surface slope.

## Contract

The scalar symbol is `convex_polygon_minimax_eccentricity_edge_insertion`.
Input is `[N, x0, y0, ..., x(N-1), y(N-1)]`, with `3 <= N <= 6`, integer
coordinates in `[-4,4]`, and vertices supplied in strict convex boundary order
(clockwise or counterclockwise). No three vertices may be collinear. The input
length must equal `1+2*N`; the maximum valid and parseable lengths are 13 and
14 i64 words. Invalid or null input returns `-1`.

The output is the one-based rank of the optimum maximum squared eccentricity
among the distinct squared eccentricities of every three-vertex subset. Equal
rational scores share a rank. Squaring preserves the objective's order and
allows exact integer comparisons.

For triangle side squares `A`, `B`, and `C`, with `C` the largest, the score is
zero when `C <= A+B`. Otherwise the triangle is obtuse and its squared
eccentricity is

`C * (C-A-B)^2 / (16 * area2^2)`,

where `area2` is the absolute doubled area. This follows from the distance of
the circumcenter to the opposite side, `R*|cos(angle)|`. Fractions are reduced
and compared by cross multiplication; the coordinate bound keeps every
intermediate within signed 64-bit range.

## Algorithm

The primary starts with a fan at vertex zero. For each positive-score worst
triangle, it considers each largest-angle vertex as an anchor, breaking anchor
ties by vertex order. It tries absent chords from that anchor which cross the
opposite edge. Inserting a chord deletes every crossed diagonal; the bounded
retessellation step enumerates only triangulations that preserve every
uncrossed old edge and contain the inserted chord. It accepts a strict
improvement: a lower maximum score, or an equal maximum with a proper subset
of the previous worst-triangle set. It restarts after the first accepted
insertion. There are at most 14 triangulations for this bound.

Bern et al. prove that eccentricity has the weak anchor property needed by the
edge-insertion method. For positive eccentricity, a largest-angle vertex is a
candidate anchor; the paper's Lemma 7.1 establishes that an improving
triangulation must break the worst triangle at such an anchor. Zero is already
the global lower bound. The independent reference instead enumerates every
triangulation and directly minimizes its maximum triangle score. The bounded
primary is an exact clean-room profile; it does not claim the paper's general
`O(n^3)` implementation details or asymptotic performance.

This measure is distinct from
[`convex_polygon_minimax_angle_edge_insertion`](../convex_polygon_minimax_angle_edge_insertion/README.md),
which minimizes the maximum angle;
[`max_min_triangle_height_triangulation`](../../m/max_min_triangle_height_triangulation/README.md),
which maximizes the minimum altitude; and
[`convex_polygon_minimax_slope_edge_insertion`](../convex_polygon_minimax_slope_edge_insertion/README.md),
which minimizes maximum slope on a lifted surface. It also differs from
Delaunay triangulation's max-min-angle objective.

## Provenance and rights

The objective and edge-insertion result are described in Tiow-Seng Tan,
[“Optimal Triangulation,” *Encyclopedia of Algorithms*](https://doi.org/10.1007/978-1-4939-2864-4_715),
and the primary source is Bern, Edelsbrunner, Eppstein, Mitchell, and Tan,
[“Edge Insertion for Optimal Triangulations”](https://doi.org/10.1007/BF02573962)
([author-hosted paper](https://people.eecs.berkeley.edu/~jrs/meshpapers/BEEMT.pdf)).
The publications remain copyrighted. This package uses their problem definition,
proof ideas, and algorithm outline only; its contract, exact bounded
retessellation, workload, oracles, and ports are independently authored. See
[`RIGHTS.md`](RIGHTS.md), [`workload.json`](workload.json), the
[primary oracle](../../convex_polygon_minimax_eccentricity_edge_insertion_oracle.py),
the [independent oracle](../../convex_polygon_minimax_eccentricity_edge_insertion_verifier_oracle.py),
and the [static inventory](../../check_convex_polygon_minimax_eccentricity_edge_insertion_package.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/c/convex_polygon_minimax_eccentricity_edge_insertion.c`](../../../c/c/convex_polygon_minimax_eccentricity_edge_insertion.c) |
| C3 | [`c3/c/convex_polygon_minimax_eccentricity_edge_insertion.c3`](../../../c3/c/convex_polygon_minimax_eccentricity_edge_insertion.c3) |
| C++ | [`cpp/c/convex_polygon_minimax_eccentricity_edge_insertion.cpp`](../../../cpp/c/convex_polygon_minimax_eccentricity_edge_insertion.cpp) |
| Elisa | [`elisa/c/convex_polygon_minimax_eccentricity_edge_insertion.elisa`](../../../elisa/c/convex_polygon_minimax_eccentricity_edge_insertion.elisa) |
| Mojo | [`mojo/c/convex_polygon_minimax_eccentricity_edge_insertion.mojo`](../../../mojo/c/convex_polygon_minimax_eccentricity_edge_insertion.mojo) |
| Nim | [`nim/c/convex_polygon_minimax_eccentricity_edge_insertion.nim`](../../../nim/c/convex_polygon_minimax_eccentricity_edge_insertion.nim) |
| Odin | [`odin/c/convex_polygon_minimax_eccentricity_edge_insertion.odin`](../../../odin/c/convex_polygon_minimax_eccentricity_edge_insertion.odin) |
| Rust | [`rust/c/convex_polygon_minimax_eccentricity_edge_insertion.rs`](../../../rust/c/convex_polygon_minimax_eccentricity_edge_insertion.rs) |
| V | [`v/c/convex_polygon_minimax_eccentricity_edge_insertion.v`](../../../v/c/convex_polygon_minimax_eccentricity_edge_insertion.v) |
| Zig | [`zig/c/convex_polygon_minimax_eccentricity_edge_insertion.zig`](../../../zig/c/convex_polygon_minimax_eccentricity_edge_insertion.zig) |
