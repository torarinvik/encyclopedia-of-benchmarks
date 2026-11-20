# Stochastic visibility walk in a triangulation

This package profiles point location by walking between adjacent triangles. A
face is outside the query's location when the query lies strictly beyond one
of that CCW face's supporting edge lines. The walk crosses the unique
separating edge when there is one; when two qualify, a supplied choice bit
selects the first or second edge in local face order. This is the bounded,
deterministic replay of a stochastic visibility walk described by the
Encyclopedia chapter and the triangulation-walking paper.

## Contract

The exported scalar ABI is `i64_array_scalar` and the symbol is
`triangulation_stochastic_visibility_walk`. Input is
`[V,B,T,start_face,px,py,step_cap,K,(x,y)*V,boundary_vertex_ids*B,(a,b,c)*T,choice_bits*K]`.

- `3<=V<=6`, `3<=B<=V`, and `T=2V-B-2<=7`.
- Boundary vertices are unique and form a strictly convex CCW polygon. Every
  nonboundary vertex lies strictly inside it. Coordinates are integers in
  `[-200,200]`.
- Every face contains three distinct vertex IDs, is nondegenerate and CCW,
  and the supplied faces exactly triangulate the convex hull. Each boundary
  edge occurs once; every other edge occurs twice.
- The query lies strictly inside the hull and exactly one face. The supplied
  `start_face` is any initial face; no preprocessing or starting-point search
  is included.
- `0<=step_cap<=12`. It limits crossed edges. The current face is still
  checked after the cap is reached, so a query in that face returns located.
- `0<=K<=12`, and every choice symbol is 0 or 1. A bit is consumed only when
  exactly two edges separate the current face from the query. Zero selects
  the first eligible edge in `(v0,v1),(v1,v2),(v2,v0)` order; one selects the
  second. Unused trailing bits are ignored.
- The output trace starts with `start_face` and appends every face entered,
  each as a base-9 digit `face_id+1`. The scalar result is
  `((trace_code*40 + edge_predicate_count)*3 + status)`, with status 0 for
  located, 1 for choice-tape exhaustion at a two-successor branch, and 2 for
  reaching the step cap before the next crossing. Invalid frames return `-1`.
- Maximum valid frame length is 56 signed 64-bit words; a single trailing
  word (length 57) is parseable and rejected. The conservative scalar output
  upper bound is `305023899399479`, safely within signed 64-bit range.

## Source comparison

Chapter 587, [“Point Location”](https://doi.org/10.1007/978-1-4939-2864-4_587),
illustrates straight-line, orthogonal, and visibility walks. This package
selects the visibility-walk successor rule. Devillers, Pion, and Teillaud's
[“Walking in a Triangulation”](https://doi.org/10.1142/S0129054102001047)
defines the separating-edge transition and stochastic branch handling in
detail. The code is clean-room and uses only those algorithm descriptions.

This work differs from local
[`kirkpatrick_hierarchical_point_location`](../../k/kirkpatrick_hierarchical_point_location/README.md),
which scans candidates in a supplied hierarchy, and
[`point_location_sweep`](../point_location_sweep/README.md), which answers a
batch of vertical-ray queries with an offline event sweep. No existing package
replays face-adjacency visibility-walk transitions.

The primary oracle validates and follows local neighbor links directly. The
independent oracle validates the geometry through a separate edge-owner model,
then constructs a per-face transition table and replays the supplied choice
tape over that table. The workload includes direct
location, deterministic and ambiguous transitions, tape exhaustion, cap
handling, a maximum-size frame, and malformed input. The static checker
reviews package inventory and source presence. No programs, tests, scripts,
checkers, builds, compilers, profilers, or benchmarks were run while preparing
this package.

See [`RIGHTS.md`](RIGHTS.md) for provenance.

| Language | Source |
|---|---|
| C | [`c/p/triangulation_stochastic_visibility_walk.c`](../../../c/p/triangulation_stochastic_visibility_walk.c) |
| C3 | [`c3/p/triangulation_stochastic_visibility_walk.c3`](../../../c3/p/triangulation_stochastic_visibility_walk.c3) |
| C++ | [`cpp/p/triangulation_stochastic_visibility_walk.cpp`](../../../cpp/p/triangulation_stochastic_visibility_walk.cpp) |
| Elisa | [`elisa/p/triangulation_stochastic_visibility_walk.elisa`](../../../elisa/p/triangulation_stochastic_visibility_walk.elisa) |
| Mojo | [`mojo/p/triangulation_stochastic_visibility_walk.mojo`](../../../mojo/p/triangulation_stochastic_visibility_walk.mojo) |
| Nim | [`nim/p/triangulation_stochastic_visibility_walk.nim`](../../../nim/p/triangulation_stochastic_visibility_walk.nim) |
| Odin | [`odin/p/triangulation_stochastic_visibility_walk.odin`](../../../odin/p/triangulation_stochastic_visibility_walk.odin) |
| Rust | [`rust/p/triangulation_stochastic_visibility_walk.rs`](../../../rust/p/triangulation_stochastic_visibility_walk.rs) |
| V | [`v/p/triangulation_stochastic_visibility_walk.v`](../../../v/p/triangulation_stochastic_visibility_walk.v) |
| Zig | [`zig/p/triangulation_stochastic_visibility_walk.zig`](../../../zig/p/triangulation_stochastic_visibility_walk.zig) |
