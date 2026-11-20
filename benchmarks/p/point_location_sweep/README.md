# Offline sweep-line point location

This package profiles batched vertical-ray shooting in a planar straight-line
subdivision. It sweeps edge endpoints and query x-coordinates from left to
right, keeping nonvertical edges ordered by their height at the current x.
Each query binary-searches that active order for the nearest edge at or below
the query point. An edge carries the face on its upper side, as in a DCEL-based
point-location interface.

## Contract

The scalar ABI and exported symbol are `i64_array_scalar` and
`point_location_sweep`. Input is
`[N,M,Q,F,(x,y)*N,(u,v,above_face)*M,(qx,qy)*Q]`:

- `2<=N<=16`, `1<=M<=24`, `0<=Q<=16`, and `1<=F<=16`.
- Vertex and query coordinates are integers in `[-300,300]`. Vertex x
  coordinates are distinct, so no edge is vertical. Every query x differs
  from every vertex x.
- Edge endpoints are zero-based vertex IDs; undirected edges are unique.
  Edges form a noncrossing straight-line embedding: two edges may meet only
  at a shared endpoint, and incident edges may not be collinear.
- `above_face` is the face on the upper side of the edge when oriented from
  its smaller-x endpoint to its larger-x endpoint. It is `-1` for the outer
  face and otherwise in `0..F-1`. The input supplies face labels from its
  planar subdivision/DCEL representation.
- Queries are located by the first edge at or above their y-coordinate. If
  that edge has exactly the query's height, return `F+edge_id+1` (boundary
  edge code, with zero-based input edge IDs). Otherwise return the label of
  the face above the nearest edge below, plus one; return `0` for the outer
  face or when no edge lies below.
- The scalar result is `sum((query_number+1)*response)` in input query order.
  Unknown/malformed frames, invalid graph geometry, or out-of-range labels
  return `-1`.

The exact frame length is `4+2*N+3*M+2*Q`; maximum valid and parseable lengths
are 140 and 141 signed 64-bit words. The maximum response is 40 and the
maximum scalar result is 5440.

## Sweep order and distinctness

For each edge, the sweep creates an add event at its smaller endpoint x and a
remove event at its larger endpoint x. At a shared x, all removals happen
before additions; additions are ordered by exact height immediately to the
right of that x, with slope and edge ID as deterministic tie-breakers. Queries
at vertex x-coordinates are invalid, so no query shares an endpoint event.
This keeps the active order unambiguous for all accepted frames.

The local [`kirkpatrick_hierarchical_point_location`](../../k/kirkpatrick_hierarchical_point_location/README.md)
package queries a supplied triangle hierarchy. The local
[`point_in_polygon_ray_casting`](../point_in_polygon_ray_casting/README.md)
scans every polygon edge for each query. This package instead sweeps many
queries together and maintains an edge order that changes only at endpoint
events.

## References and review

The algorithm idea comes from CP-Algorithms'
[Point location in O(log n)](https://cp-algorithms.com/geometry/point-location.html),
which describes processing vertical-edge, query, removal, and insertion events
while maintaining active nonvertical edges by height. This bounded contract
excludes vertical edges and query x-coordinates equal to vertices, and records
face labels explicitly. The primary oracle uses the sweep and active order;
the independent oracle scans all edges separately for every query.
[`workload.json`](workload.json) contains hand-derived fixtures, including a
maximum valid frame. The package checker reviews fixture outputs, Markdown
links, and the ten source files. Ports have not been compiled or run.

| Language | Source |
|---|---|
| C | [`c/p/point_location_sweep.c`](../../../c/p/point_location_sweep.c) |
| C3 | [`c3/p/point_location_sweep.c3`](../../../c3/p/point_location_sweep.c3) |
| C++ | [`cpp/p/point_location_sweep.cpp`](../../../cpp/p/point_location_sweep.cpp) |
| Elisa | [`elisa/p/point_location_sweep.elisa`](../../../elisa/p/point_location_sweep.elisa) |
| Mojo | [`mojo/p/point_location_sweep.mojo`](../../../mojo/p/point_location_sweep.mojo) |
| Nim | [`nim/p/point_location_sweep.nim`](../../../nim/p/point_location_sweep.nim) |
| Odin | [`odin/p/point_location_sweep.odin`](../../../odin/p/point_location_sweep.odin) |
| Rust | [`rust/p/point_location_sweep.rs`](../../../rust/p/point_location_sweep.rs) |
| V | [`v/p/point_location_sweep.v`](../../../v/p/point_location_sweep.v) |
| Zig | [`zig/p/point_location_sweep.zig`](../../../zig/p/point_location_sweep.zig) |

See [`RIGHTS.md`](RIGHTS.md) for source licensing and provenance.
