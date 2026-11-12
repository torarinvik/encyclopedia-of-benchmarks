# Count Points in Triangle

For each indexed triple of points from a fixed set A, count points from a
second fixed set B that lie strictly inside the triple's convex hull. Points
on an edge or vertex do not count. Collinear or repeated-vertex triples have
empty two-dimensional interior and return zero.

## Algorithm

For each anchor in A, sort the nonzero vectors to B by exact polar angle and
build a Fenwick tree over their sorted positions. Vectors from the anchor to
coincident B points are counted separately because they lie on every line
through that anchor. A closed half-plane or circular angular interval is then
counted with two ray-bound searches and a Fenwick range sum.

For a counterclockwise triangle, each of its three exterior closed
half-planes contributes one set. Inclusion-exclusion gives the strict
interior count as `|B| - sum(single exterior counts) + sum(adjacent pair
intersections)`. The triple intersection of the three exterior half-planes is
empty for a nondegenerate convex triangle. Each adjacent pair intersection is
the angular wedge at the shared vertex. Clockwise triples are reordered;
degenerate triples return zero. Integer cross products compare rays without
floating point.

The primary oracle uses this angular/Fenwick method. The independent oracle
checks each point directly against the three oriented edges.

## Bounded contract

The `i64_array_bytes_output` entry point is
`count_points_in_triangle(input, length, output, capacity)`. Input is
`[N,M,Q, A-pairs..., B-pairs..., (a,b,c)...]`, with 1<=N,M<=24, 1<=Q<=128,
and all coordinates in `[-10^9,10^9]`. Query indices are zero-based. Output is
Q little-endian signed 64-bit counts, so success returns `8*Q` bytes.
Malformed input returns `-1`; valid input with null or undersized output
returns `-2`. Errors leave output unchanged. The maximum input is 483 words,
the maximum output is 1024 bytes, and fixed workspace is 65536 bytes.

[`workload.json`](workload.json) records the bounded workload and fixtures.
[`verify_workload.py`](verify_workload.py) statically checks fixture/oracle
agreement, provenance, and the ten source paths; it has not been run.

## Provenance and rights

The operation comes from Library Checker's
[Count Points in Triangle task](https://github.com/yosupo06/library-checker-problems/blob/master/geo/count_points_in_triangle/task.md).
The local angular/Fenwick implementation and direct oracle are clean-room
work. See [`RIGHTS.md`](RIGHTS.md).

## Implementations

| Language | Source |
|---|---|
| C | [`c/c/count_points_in_triangle.c`](../../../c/c/count_points_in_triangle.c) |
| C3 | [`c3/c/count_points_in_triangle.c3`](../../../c3/c/count_points_in_triangle.c3) |
| C++ | [`cpp/c/count_points_in_triangle.cpp`](../../../cpp/c/count_points_in_triangle.cpp) |
| Elisa | [`elisa/c/count_points_in_triangle.elisa`](../../../elisa/c/count_points_in_triangle.elisa) |
| Mojo | [`mojo/c/count_points_in_triangle.mojo`](../../../mojo/c/count_points_in_triangle.mojo) |
| Nim | [`nim/c/count_points_in_triangle.nim`](../../../nim/c/count_points_in_triangle.nim) |
| Odin | [`odin/c/count_points_in_triangle.odin`](../../../odin/c/count_points_in_triangle.odin) |
| Rust | [`rust/c/count_points_in_triangle.rs`](../../../rust/c/count_points_in_triangle.rs) |
| V | [`v/c/count_points_in_triangle.v`](../../../v/c/count_points_in_triangle.v) |
| Zig | [`zig/c/count_points_in_triangle.zig`](../../../zig/c/count_points_in_triangle.zig) |

Root owns shared suite registration and benchmark-corpus wiring.
