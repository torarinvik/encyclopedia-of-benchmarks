# Point add rectangle sum

This benchmark keeps a dynamic multiset of weighted points in a large sparse
coordinate plane. A point-add operation appends a point, including when the
same coordinate already exists. A rectangle query returns the total weight in
a half-open rectangle. The ports use an offline coordinate-compressed
Fenwick tree of Fenwick trees: every possible update coordinate is registered
before processing operations, each outer Fenwick node stores its own sorted
set of y-ranks, and each nested Fenwick tree stores point weights. Rectangle
sums use four two-dimensional prefix queries.

## Contract

Input is a signed 64-bit array `[N,Q,initial_points,operations]`. Each initial
point is `(x,y,w)`. Operation `0` contains `(x,y,w)` and adds a new point;
operation `1` contains `(left,down,right,up)` and queries
`left <= x < right` and `down <= y < up`. Duplicate coordinates remain
separate weighted points. Coordinates and weights are in `[0,1,000,000]`;
rectangle bounds satisfy `0 <= left < right <= 1,000,000` and
`0 <= down < up <= 1,000,000`. The local bounds are `1 <= N <= 32` and
`0 <= Q <= 32`. Point-add records have four total fields including the opcode;
rectangle-query records have five. The maximum valid input is 258 integers;
one additional trailing integer is parseable and rejected.

Successful calls write one signed 64-bit little-endian sum per query and
return the byte count. Invalid input returns `-1`; null or insufficient output
returns `-2` without writing. At most 32 answers require a 256-byte output
buffer. The fixed coordinate tables are bounded by `N+Q <= 64`; each update
and each rectangle query takes `O(log^2(N+Q))` time after coordinate
registration. The bounded ports use insertion sort for the compressed
coordinate lists, so setup is `O((N+Q)^2)` in this local profile.

The [official task](https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/point_add_rectangle_sum/task.md)
allows `N,Q <= 100,000`, with coordinates and weights through `10^9`; these
local caps bound the fixed nested tables while preserving the sparse dynamic
point-add and half-open rectangle-query workload. The independent oracle
scans the current point list directly for every query.

This differs from [`segment_tree2_d`](../../s/segment_tree2_d/README.md), which
uses a dense grid, point assignment, and nested segment trees. It also differs
from [`prefix_sum2_d`](../../p/prefix_sum2_d/README.md), which answers static
queries over a fixed matrix. The measured structure here is an offline
compressed 2D Fenwick-of-vectors for point additions in a sparse coordinate
domain.

## Workload and oracle

[`workload.json`](workload.json) covers duplicate points, online additions,
half-open boundaries, empty query traces, malformed operation framing, and
output-capacity errors. The independent
[`benchmarks/point_add_rectangle_sum_oracle.py`](../../point_add_rectangle_sum_oracle.py)
uses direct point scans rather than coordinate compression or Fenwick trees.

## Implementations

| Language | Source |
|---|---|
| C | [`c/p/point_add_rectangle_sum.c`](../../../c/p/point_add_rectangle_sum.c) |
| C3 | [`c3/p/point_add_rectangle_sum.c3`](../../../c3/p/point_add_rectangle_sum.c3) |
| C++ | [`cpp/p/point_add_rectangle_sum.cpp`](../../../cpp/p/point_add_rectangle_sum.cpp) |
| Elisa | [`elisa/p/point_add_rectangle_sum.elisa`](../../../elisa/p/point_add_rectangle_sum.elisa) |
| Mojo | [`mojo/p/point_add_rectangle_sum.mojo`](../../../mojo/p/point_add_rectangle_sum.mojo) |
| Nim | [`nim/p/point_add_rectangle_sum.nim`](../../../nim/p/point_add_rectangle_sum.nim) |
| Odin | [`odin/p/point_add_rectangle_sum.odin`](../../../odin/p/point_add_rectangle_sum.odin) |
| Rust | [`rust/p/point_add_rectangle_sum.rs`](../../../rust/p/point_add_rectangle_sum.rs) |
| V | [`v/p/point_add_rectangle_sum.v`](../../../v/p/point_add_rectangle_sum.v) |
| Zig | [`zig/p/point_add_rectangle_sum.zig`](../../../zig/p/point_add_rectangle_sum.zig) |
