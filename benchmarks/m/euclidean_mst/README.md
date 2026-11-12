# Euclidean minimum spanning tree

Return the edges of a minimum spanning tree over a bounded set of planar
points. The implementation generates Delaunay candidates with an exact
empty-circumcircle test, then runs Kruskal on those candidates. The oracle's
certificate checks the output tree against every edge in the complete metric
graph.

## Contract

Input is `[n, x0, y0, ..., x(n-1), y(n-1)]`, with zero-based point indices and
integer coordinates in `[-10, 10]`. This profile has `1 <= n <= 8`, distinct
points, no collinear triple when `n >= 3`, and no cocircular quadruple. The
general-position bounds give a unique Delaunay triangulation. They narrow the
official task, which allows up to 200,000 points and also permits degeneracies.

Output is a little-endian signed-i64 byte array `[n-1, u0, v0, ...]`, listing
the selected tree edges in deterministic Kruskal order: squared distance,
then smaller endpoint, then larger endpoint. The output occupies
`8 * (2*n - 1)` bytes, at most 120 bytes. Invalid input returns `-1`; a null
or undersized output buffer returns `-2` without writes.

The source task is [Library Checker Euclidean
MST](https://judge.yosupo.jp/problem/euclidean_mst). It defines the complete
graph with Euclidean edge lengths and accepts any minimum spanning tree. Since
the square root preserves edge order, the bounded ports sort by exact squared
distance and avoid floating point.

## Algorithm and distinctness

For each non-collinear point triple, the ports compute its integer incircle
determinant and keep its three sides when no other point is inside the
circumcircle. These empty-circle triangles yield the Delaunay candidate edges.
Kruskal then selects a minimum spanning tree from that sparse graph. The
bounded implementation takes `O(n^4 + n^2 log n)` time and `O(n^2)` space.

This is distinct from [`manhattan_mst`](../manhattan_mst/README.md), which
uses direct Prim over an implicit complete L1 graph, and from generic explicit
edge-list MSTs. The local [`delaunay_triangulation`](../../d/delaunay_triangulation/README.md)
package returns a triangulation; it does not select a minimum spanning tree.
The independent oracle uses the same exact empty-circle rule to produce
canonical expected bytes, while a separate complete-graph cycle-property
checker validates any returned MST.

See [`workload.json`](workload.json) and the
[oracle](../../euclidean_mst_oracle.py).

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/m/euclidean_mst.c`](../../../c/m/euclidean_mst.c) |
| C3 | [`c3/m/euclidean_mst.c3`](../../../c3/m/euclidean_mst.c3) |
| C++ | [`cpp/m/euclidean_mst.cpp`](../../../cpp/m/euclidean_mst.cpp) |
| Elisa | [`elisa/m/euclidean_mst.elisa`](../../../elisa/m/euclidean_mst.elisa) |
| Mojo | [`mojo/m/euclidean_mst.mojo`](../../../mojo/m/euclidean_mst.mojo) |
| Nim | [`nim/m/euclidean_mst.nim`](../../../nim/m/euclidean_mst.nim) |
| Odin | [`odin/m/euclidean_mst.odin`](../../../odin/m/euclidean_mst.odin) |
| Rust | [`rust/m/euclidean_mst.rs`](../../../rust/m/euclidean_mst.rs) |
| V | [`v/m/euclidean_mst.v`](../../../v/m/euclidean_mst.v) |
| Zig | [`zig/m/euclidean_mst.zig`](../../../zig/m/euclidean_mst.zig) |
