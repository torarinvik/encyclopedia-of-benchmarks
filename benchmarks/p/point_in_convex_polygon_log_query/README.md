# Logarithmic point-in-convex-polygon queries

This benchmark answers batched membership queries in a strictly convex polygon. It uses the polygon's counterclockwise radial fan and binary search to select one triangle per query. The local `point_in_polygon_ray_casting` package handles general polygons with a linear crossing scan; this package measures the convex-specific logarithmic query method.

## Contract

The exported symbol is `point_in_convex_polygon_log_query` with the `i64_array_bytes_output` ABI. Input is `[N,Q,(x,y)*N,(qx,qy)*Q]`. `3<=N<=32`, `0<=Q<=32`, and all coordinates are in `[-1,000,000,1,000,000]`. Polygon vertices are counterclockwise and strictly convex; any cyclic start is accepted. Repeated vertices and collinear consecutive edges are invalid. The exact valid input length is `2+2*N+2*Q`, at most 130 signed i64 words; the parser also accepts one trailing word for malformed-frame checks.

The output is one little-endian signed i64 per query: `1` means inside or on the boundary, and `0` means outside. The function returns bytes written. Malformed input returns `-1`; null output for a nonempty result or insufficient capacity returns `-2` without writing. Validation precedes output checks. A valid `Q=0` call returns zero bytes and permits a null output. Maximum output capacity and fixed workspace are 256 and 8,192 bytes.

The primary oracle translates the lexicographically smallest polygon vertex to the origin and binary-searches the radial fan. The independent oracle scans every polygon edge with exact even–odd ray crossing and a separate boundary test. Polygon validation is bounded `O(N^2)`; each primary query takes `O(log N)` and each independent query takes `O(N)`.

## Provenance and rights

The [CP-Algorithms convex-polygon membership article](https://cp-algorithms.com/geometry/point-in-convex-polygon.html) describes the radial-fan binary-search method and states its CC BY-SA 4.0 license. This package uses only the high-level algorithm description. The contract, fixtures, oracles, and ten language ports are clean-room work. See [`RIGHTS.md`](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [`c/p/point_in_convex_polygon_log_query.c`](../../../c/p/point_in_convex_polygon_log_query.c) |
| C3 | [`c3/p/point_in_convex_polygon_log_query.c3`](../../../c3/p/point_in_convex_polygon_log_query.c3) |
| C++ | [`cpp/p/point_in_convex_polygon_log_query.cpp`](../../../cpp/p/point_in_convex_polygon_log_query.cpp) |
| Elisa | [`elisa/p/point_in_convex_polygon_log_query.elisa`](../../../elisa/p/point_in_convex_polygon_log_query.elisa) |
| Mojo | [`mojo/p/point_in_convex_polygon_log_query.mojo`](../../../mojo/p/point_in_convex_polygon_log_query.mojo) |
| Nim | [`nim/p/point_in_convex_polygon_log_query.nim`](../../../nim/p/point_in_convex_polygon_log_query.nim) |
| Odin | [`odin/p/point_in_convex_polygon_log_query.odin`](../../../odin/p/point_in_convex_polygon_log_query.odin) |
| Rust | [`rust/p/point_in_convex_polygon_log_query.rs`](../../../rust/p/point_in_convex_polygon_log_query.rs) |
| V | [`v/p/point_in_convex_polygon_log_query.v`](../../../v/p/point_in_convex_polygon_log_query.v) |
| Zig | [`zig/p/point_in_convex_polygon_log_query.zig`](../../../zig/p/point_in_convex_polygon_log_query.zig) |

See [`workload.json`](workload.json), the [primary oracle](../../point_in_convex_polygon_log_query_oracle.py), the [independent verifier](../../point_in_convex_polygon_log_query_verifier_oracle.py), and the package-local static [inventory checker](../../check_point_in_convex_polygon_log_query_package.py).
