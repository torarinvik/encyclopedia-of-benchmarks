# Half-plane intersection

This benchmark constructs the common feasible region of oriented planar half-planes. It uses the sort-and-incremental angle ordering with a deque that removes boundary lines made redundant at either end. Existing line/segment intersection, point-in-polygon, convex hull/layers, polygon triangulation, and Minkowski-sum packages do not construct this shared feasible region.

## Contract

The exported symbol is `half_plane_intersection` with the `i64_array_bytes_output` ABI. Input is `[N,(a,b,c)*N]`, describing closed inequalities `a*x+b*y<=c`. `N` is 0 through 12; each coefficient `a,b` is in [-16,16], each `c` is in [-128,128], `(a,b)` is nonzero, and `gcd(|a|,|b|)=1`. The input length must equal `1+3*N`, so at most 37 signed i64 words are valid. The implicit constraints `-256<=x<=256` and `-256<=y<=256` bound the result.

The output is `[V,(x_num,x_den,y_num,y_den)*V]`, where each fraction is reduced with a positive denominator. Vertices are counterclockwise, beginning at the minimum y-coordinate and then minimum x-coordinate. Empty intersections and zero-area intersections both encode as `[0]`. At most 16 vertices are emitted, for a maximum of 520 output bytes. The function returns bytes written; malformed input returns `-1`; null output or insufficient capacity returns `-2` without writing. Input validation precedes output-capacity checks. The fixed workspace budget is 8,192 bytes.

The primary algorithm sorts constraints by normal angle, keeps the tightest constraint for repeated same-direction normals, and incrementally prunes a deque using exact rational line intersections and integer side tests. It takes `O(N log N)` time and `O(N)` workspace. The independent oracle enumerates feasible pairwise boundary intersections and constructs their exact monotone-chain hull in `O(N^3 log N)` bounded time. Both return the same canonical rational vertex cycle.

## Provenance and rights

The [CP-Algorithms half-plane intersection article](https://cp-algorithms.com/geometry/halfplane-intersection.html) describes the O(N log N) sort-and-incremental deque method and identifies the bounding-box and parallel-line cases. The article repository uses CC BY-SA 4.0. This package uses only the high-level algorithm description; its contract, fixtures, oracles, and ten language ports are clean-room work. See [`RIGHTS.md`](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [`c/h/half_plane_intersection.c`](../../../c/h/half_plane_intersection.c) |
| C3 | [`c3/h/half_plane_intersection.c3`](../../../c3/h/half_plane_intersection.c3) |
| C++ | [`cpp/h/half_plane_intersection.cpp`](../../../cpp/h/half_plane_intersection.cpp) |
| Elisa | [`elisa/h/half_plane_intersection.elisa`](../../../elisa/h/half_plane_intersection.elisa) |
| Mojo | [`mojo/h/half_plane_intersection.mojo`](../../../mojo/h/half_plane_intersection.mojo) |
| Nim | [`nim/h/half_plane_intersection.nim`](../../../nim/h/half_plane_intersection.nim) |
| Odin | [`odin/h/half_plane_intersection.odin`](../../../odin/h/half_plane_intersection.odin) |
| Rust | [`rust/h/half_plane_intersection.rs`](../../../rust/h/half_plane_intersection.rs) |
| V | [`v/h/half_plane_intersection.v`](../../../v/h/half_plane_intersection.v) |
| Zig | [`zig/h/half_plane_intersection.zig`](../../../zig/h/half_plane_intersection.zig) |

See [`workload.json`](workload.json), the [primary oracle](../../half_plane_intersection_oracle.py), the [independent verifier](../../half_plane_intersection_verifier_oracle.py), and the package-local static [inventory checker](../../check_half_plane_intersection_package.py).
