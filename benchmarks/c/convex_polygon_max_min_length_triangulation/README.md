# Max-min length triangulation

This benchmark constructs a triangulation of a small strictly convex polygon
whose shortest edge is as long as possible. It follows Hu's linear-time
60-degree corner-cutting algorithm and compares lengths by their exact
squares.

## Contract

The ABI is `i64_array_scalar`; the exported symbol is
`convex_polygon_max_min_length_triangulation`. Input is `[n,x0,y0,...,x(n-1),y(n-1)]` with
3 to 6 distinct points, coordinates in `[-8,8]`, and vertices in strict
counterclockwise boundary order. The polygon must be strictly convex, with
no three vertices collinear. Exact frame length is `1+2*n`; the parser accepts
up to one trailing word to reject it explicitly. Invalid and null input
returns `-1`.

The packed scalar is `minimum_squared_edge_length*512 + diagonal_mask`.
Squaring preserves the ordering of nonnegative lengths and avoids floating
point. The objective is from 1 through 512; the nine-bit mask is from 0
through 511. Valid results are at most 262,655. For a triangle there are no
diagonals, so its mask is zero and the result still carries the squared
shortest-side objective.

Hu defines the objective over every edge of the triangulation, including the
fixed polygon boundary. The paper's theorem that an optimal shortest edge is
on the hull means the high part alone equals the shortest hull-edge square;
the diagonal mask makes the constructed triangulation observable as well.

## Algorithm and ties

Start from vertex zero and track the active polygon with circular successor
links. For active neighbors `p,q,r`, inspect the interior angle at `q`. Cut
`q` and add chord `p-r` when its angle is at least 60 degrees; otherwise
advance to the next corner. The exact test uses vectors `u=p-q`, `v=r-q`:
nonpositive dot product means the angle is at least 90 degrees, and for a
positive dot product compare `4*(u·v)^2 <= (u·u)*(v·v)`. Equality is handled
as a cut. Once three active vertices remain, the hull edges and inserted
chords form the triangulation. The high part of the result is the minimum
squared length over those edges. The low nine bits record which diagonals
were inserted. Bit positions follow lexicographic `(i,j)` order over all
`i<j`, skipping polygon boundary edges.

Hu proves that every convex polygon has at most two interior angles below 60
degrees and that the inserted chords preserve the shortest hull-edge bound.
Each active remainder is still convex, so a cut is found within at most three
corner checks and there are `n-3` cuts; the workload caps total checks at
`4*n`. Hu also proves that an
optimal triangulation has a shortest edge on the polygon boundary, making
the maximum minimum length equal to the shortest hull edge. The independent
oracle verifies the result by enumerating every triangulation instead.

The deterministic tie rules are: begin at vertex zero, follow input order,
and cut on an exact 60-degree equality. Equal squared edge lengths do not
change the branch. The diagonal mask makes the chosen triangulation visible
even when its optimum score equals the fixed shortest hull edge. The bound
allows at most 14 triangulations in the exhaustive oracle.

This objective differs from the neighboring
[`max_min_triangle_height_triangulation`](../../m/max_min_triangle_height_triangulation/README.md)
benchmark: this profile maximizes the shortest edge length, while that one
maximizes the least triangle altitude. It also differs from
`convex_polygon_minimax_length_triangulation`, which minimizes the longest
edge instead of maximizing the shortest.

## Provenance and ports

The source algorithm is Shiyan Hu,
[“A linear time algorithm for max-min length triangulation of a convex polygon”](https://doi.org/10.1016/j.ipl.2006.09.014),
with an [open paper copy](https://par.cse.nsysu.edu.tw/resource/paper/2008/080312/A%20linear%20time%20algorithm%20for%20max-min%20length%20triangulation%20of%20a%20convex%20polygon.pdf).
The relevant encyclopedia context is Tiow-Seng Tan,
[“Optimal Triangulation”](https://doi.org/10.1007/978-1-4939-2864-4_715).
The implementations use the algorithm description only; no published source
code was copied. See [`RIGHTS.md`](RIGHTS.md).

| Language | Source |
| --- | --- |
| C | [c/c/convex_polygon_max_min_length_triangulation.c](../../../c/c/convex_polygon_max_min_length_triangulation.c) |
| C3 | [c3/c/convex_polygon_max_min_length_triangulation.c3](../../../c3/c/convex_polygon_max_min_length_triangulation.c3) |
| C++ | [cpp/c/convex_polygon_max_min_length_triangulation.cpp](../../../cpp/c/convex_polygon_max_min_length_triangulation.cpp) |
| Elisa | [elisa/c/convex_polygon_max_min_length_triangulation.elisa](../../../elisa/c/convex_polygon_max_min_length_triangulation.elisa) |
| Mojo | [mojo/c/convex_polygon_max_min_length_triangulation.mojo](../../../mojo/c/convex_polygon_max_min_length_triangulation.mojo) |
| Nim | [nim/c/convex_polygon_max_min_length_triangulation.nim](../../../nim/c/convex_polygon_max_min_length_triangulation.nim) |
| Odin | [odin/c/convex_polygon_max_min_length_triangulation.odin](../../../odin/c/convex_polygon_max_min_length_triangulation.odin) |
| Rust | [rust/c/convex_polygon_max_min_length_triangulation.rs](../../../rust/c/convex_polygon_max_min_length_triangulation.rs) |
| V | [v/c/convex_polygon_max_min_length_triangulation.v](../../../v/c/convex_polygon_max_min_length_triangulation.v) |
| Zig | [zig/c/convex_polygon_max_min_length_triangulation.zig](../../../zig/c/convex_polygon_max_min_length_triangulation.zig) |

[`workload.json`](workload.json) covers a triangle, a right-angle cut, a
retained acute corner, tied shortest hull edges on a maximum-size hexagon,
the maximum parseable trailing-word frame, and malformed polygons.
`primary_oracle.py` implements the greedy algorithm. `independent_oracle.py`
enumerates all triangulations (at most 14), verifies that the deterministic
mask is a legal optimal triangulation, and exposes `verify_candidate` for an
independent result check. The triangle, square, pentagon, and hexagon packed
results are 4,608, 8,193, 4,620, and 8,199. [`verify_workload.py`](verify_workload.py)
is a static package inventory and fixture checker and has not been run.
