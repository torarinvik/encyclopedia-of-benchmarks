# Delaunay triangulation

This package benchmarks the planar Bowyer–Watson Delaunay triangulation from the pinned `jbegaint/delaunay-cpp` implementation. It is distinct from `ear_clipping_polygon_triangulation`, which triangulates a supplied simple polygon rather than a point set.

## Contract

- ABI: `i64_array_bytes_output`; exported symbol: `delaunay_triangulation`.
- Input is `[point_count, x0, y0, ...]` with 3–8 distinct integer points and coordinates in `[-10,10]`.
- To keep the Delaunay result unique and the pinned circumcircle test well-defined, inputs with a collinear point triple or a cocircular point quadruple are invalid. Inputs are also rejected if the pinned bbox-derived supertriangle forms a collinear triple with any input points.
- The ports preserve the pinned algorithm's bbox-derived supertriangle, insertion order, circumcenter formula, and squared-distance tolerance `dist - radius_squared <= 1e-4`. The returned triangles are canonicalized by sorting each triangle's original input indices, then sorting the triples lexicographically.
- Output is little-endian signed 64-bit words `[triangle_count, a0, b0, c0, ...]`. At most 11 triangles are possible for eight points in general position, so output is bounded by 272 bytes. Invalid input returns `-1`; a null or short output buffer returns `-2` without writes.

The pinned source is Jean Bégaint's [`delaunay.hpp`](https://github.com/jbegaint/delaunay-cpp/blob/a5735771621d889bd5b85ffc228ed358e4bf3c9b/delaunay.hpp) at commit `a5735771621d889bd5b85ffc228ed358e4bf3c9b`. The repository's MIT notice is included in [`LICENSE.md`](LICENSE.md).

## Workload and oracle

[`workload.json`](workload.json) covers one triangle, a convex quadrilateral, an interior point, and invalid duplicate, collinear, cocircular, and malformed inputs. The independent [oracle](../../delaunay_triangulation_oracle.py) enumerates empty circumcircles instead of using Bowyer–Watson.

## Implementations

| Language | Port |
|---|---|
| C | [`c/d/delaunay_triangulation.c`](../../../c/d/delaunay_triangulation.c) |
| C3 | [`c3/d/delaunay_triangulation.c3`](../../../c3/d/delaunay_triangulation.c3) |
| C++ | [`cpp/d/delaunay_triangulation.cpp`](../../../cpp/d/delaunay_triangulation.cpp) |
| Elisa | [`elisa/d/delaunay_triangulation.elisa`](../../../elisa/d/delaunay_triangulation.elisa) |
| Nim | [`nim/d/delaunay_triangulation.nim`](../../../nim/d/delaunay_triangulation.nim) |
| Odin | [`odin/d/delaunay_triangulation.odin`](../../../odin/d/delaunay_triangulation.odin) |
| Rust | [`rust/d/delaunay_triangulation.rs`](../../../rust/d/delaunay_triangulation.rs) |
| V | [`v/d/delaunay_triangulation.v`](../../../v/d/delaunay_triangulation.v) |
| Zig | [`zig/d/delaunay_triangulation.zig`](../../../zig/d/delaunay_triangulation.zig) |
