# External point tangents to a convex polygon

This package benchmarks finding the two supporting tangent vertices from an external query point to a strictly convex polygon. Vertex IDs are their zero-based positions in the input polygon; each answer pair is sorted by ID.

The algorithm follows the layered binary-search idea in the [Codeforces tutorial](https://codeforces.com/blog/entry/140112): preprocess the polygon's lower and upper x-monotone chains, binary-search each chain split by the query's x-coordinate, then use four tangent searches over the two chain portions. It uses exact integer cross products. The [Library Checker proposal](https://github.com/yosupo06/library-checker-problems/issues/1371) is included as problem provenance. All ten ports are clean-room implementations; no source code, examples, or prose are copied.

## Contract

- ABI: `i64_array_bytes_output`; symbol: `external_point_tangents_convex_polygon`.
- Input words: `[n,q,x0,y0,...,x(n-1),y(n-1),qx0,qy0,...]`.
- `n` is 3..32, `q` is 0..16, and every coordinate is in `[-1000,1000]`.
- The polygon is strictly convex and counterclockwise, in its original vertex order. Repeated or collinear consecutive vertices are invalid.
- Every query is strictly outside and is not collinear with any polygon edge's supporting line. These conditions make both tangent contacts unique vertices.
- The frame length must equal `2+2*n+2*q`. The largest valid frame has 98 words; 99 words are parseable, so an extra word is invalid.
- Each query emits two distinct original vertex IDs, sorted ascending, as little-endian signed 64-bit values. At most 32 values (256 bytes) are written.
- Malformed input returns `-1`. Valid input with a null output or insufficient capacity returns `-2` and writes nothing. A valid zero-query call with non-null output and zero capacity returns `0`; null output still returns `-2`.

Polygon validation checks every non-edge vertex against every directed edge, taking O(n²). The two monotone chains are constructed once in O(n). Each query's outside/general-position validation takes O(n), while its six tangent searches and constant number of contact checks take O(log n). The full call is O(n² + q(n + log n)); tangent lookup after validation and chain preprocessing is O(log n) per query. Storage is bounded by the 16 KiB workspace contract.

## References and package files

- Tutorial algorithm idea: [Codeforces blog entry 140112](https://codeforces.com/blog/entry/140112).
- Problem provenance: [Library Checker proposal 1371](https://github.com/yosupo06/library-checker-problems/issues/1371).
- [Rights and attribution](RIGHTS.md), [workload fixtures](workload.json), [primary oracle](primary_oracle.py), [independent direct-scan oracle](independent_oracle.py), and [static package checker](check_package.py).

| Language | Port |
|---|---|
| C | [c/e/external_point_tangents_convex_polygon.c](../../../c/e/external_point_tangents_convex_polygon.c) |
| C3 | [c3/e/external_point_tangents_convex_polygon.c3](../../../c3/e/external_point_tangents_convex_polygon.c3) |
| C++ | [cpp/e/external_point_tangents_convex_polygon.cpp](../../../cpp/e/external_point_tangents_convex_polygon.cpp) |
| Elisa | [elisa/e/external_point_tangents_convex_polygon.elisa](../../../elisa/e/external_point_tangents_convex_polygon.elisa) |
| Mojo | [mojo/e/external_point_tangents_convex_polygon.mojo](../../../mojo/e/external_point_tangents_convex_polygon.mojo) |
| Nim | [nim/e/external_point_tangents_convex_polygon.nim](../../../nim/e/external_point_tangents_convex_polygon.nim) |
| Odin | [odin/e/external_point_tangents_convex_polygon.odin](../../../odin/e/external_point_tangents_convex_polygon.odin) |
| Rust | [rust/e/external_point_tangents_convex_polygon.rs](../../../rust/e/external_point_tangents_convex_polygon.rs) |
| V | [v/e/external_point_tangents_convex_polygon.v](../../../v/e/external_point_tangents_convex_polygon.v) |
| Zig | [zig/e/external_point_tangents_convex_polygon.zig](../../../zig/e/external_point_tangents_convex_polygon.zig) |
