# Rectangle add, point get

This benchmark starts from weighted half-open rectangles. Each update appends a
new weighted rectangle, and each point query returns the total weight of all
rectangles that contain the queried coordinate. Repeated and overlapping
rectangles contribute independently.

## Contract

Input is a signed 64-bit array `[N,Q,rectangles,operations]`. Each initial
rectangle is `(left,down,right,up,weight)`. Operation `0` appends the same
five-field rectangle record; operation `1` contains `(x,y)` and asks for the
sum of weights over rectangles satisfying
`left <= x < right` and `down <= y < up`. Rectangle endpoints and query
coordinates lie in `[0,1,000,000]`, rectangles have positive width and height,
and weights lie in `[0,1,000,000]`. The local bounds are `1 <= N,Q <= 32`.
The largest valid input is 354 integers; one extra integer is parseable and
rejected. At most 32 point answers require 256 output bytes.

## Algorithm and distinctness

Each rectangle is represented by four signed corner events in a 2D difference
array: `(+w)` at `(left,down)`, `(-w)` at `(right,down)`, `(-w)` at
`(left,up)`, and `(+w)` at `(right,up)`. A point query sums all registered
events with both coordinates at most the query coordinate. The ports build an
offline coordinate-compressed Fenwick tree of Fenwick trees over every corner
that can be inserted by an initial rectangle or a later update. Each point get
and rectangle update uses `O(log^2 P)` Fenwick work, where `P` is the number
of rectangles; the bounded insertion-sort setup and dense corner-registration
scan cost `O(P^2)`. Populated nested Fenwick lists contain `O(P log P)` ranks;
fixed backing tables reserve `O(P^2)` slots at the local cap.

This is the dual operation direction of
[`point_add_rectangle_sum`](../../p/point_add_rectangle_sum/README.md): that
profile appends points and sums points in a rectangle, while this one appends
rectangles and evaluates their contribution at a point. The existing
[`segment_tree2_d`](../../s/segment_tree2_d/README.md) assigns cells in a small
dense matrix and queries rectangle sums; [`prefix_sum2_d`](../../p/prefix_sum2_d/README.md)
builds a static summed-area table. Neither measures dynamic rectangle range
updates with point-stabbing queries.

The [official Library Checker task](https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/rectangle_add_point_get/task.md)
allows `N,Q <= 100,000` and coordinates and weights up to `10^9`. These local
limits bound the static arrays while preserving append-only rectangle updates,
half-open boundaries, and point queries. The independent oracle scans the
current rectangle list directly for each point query.

## Workload and oracle

[`workload.json`](workload.json) covers overlapping rectangles, additions,
half-open edges, zero weights, empty point-query streams, invalid records, and
output-capacity errors.
[`benchmarks/rectangle_add_point_get_oracle.py`](../../rectangle_add_point_get_oracle.py)
is the direct-scan oracle. The separate
[`benchmarks/verify_rectangle_add_point_get.py`](../../verify_rectangle_add_point_get.py)
checks workload metadata, all ten source paths, and each fixture against an
independent rectangle-scan evaluator.

## Implementations

| Language | Source |
|---|---|
| C | [`c/r/rectangle_add_point_get.c`](../../../c/r/rectangle_add_point_get.c) |
| C3 | [`c3/r/rectangle_add_point_get.c3`](../../../c3/r/rectangle_add_point_get.c3) |
| C++ | [`cpp/r/rectangle_add_point_get.cpp`](../../../cpp/r/rectangle_add_point_get.cpp) |
| Elisa | [`elisa/r/rectangle_add_point_get.elisa`](../../../elisa/r/rectangle_add_point_get.elisa) |
| Mojo | [`mojo/r/rectangle_add_point_get.mojo`](../../../mojo/r/rectangle_add_point_get.mojo) |
| Nim | [`nim/r/rectangle_add_point_get.nim`](../../../nim/r/rectangle_add_point_get.nim) |
| Odin | [`odin/r/rectangle_add_point_get.odin`](../../../odin/r/rectangle_add_point_get.odin) |
| Rust | [`rust/r/rectangle_add_point_get.rs`](../../../rust/r/rectangle_add_point_get.rs) |
| V | [`v/r/rectangle_add_point_get.v`](../../../v/r/rectangle_add_point_get.v) |
| Zig | [`zig/r/rectangle_add_point_get.zig`](../../../zig/r/rectangle_add_point_get.zig) |
