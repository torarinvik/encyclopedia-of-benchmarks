# Circle-line intersection count

For one circle, classify each supplied infinite line by the number of real
intersection points: zero, one tangent point, or two secant points. The
contract returns counts rather than floating-point coordinates so all ports
can use exact integer arithmetic, including exact tangency.

## Contract

The byte-output ABI symbol is `circle_line_intersection_count`. Input is
`[cx,cy,r,Q,(a,b,c)*Q]`, where the circle is centered at `(cx,cy)` with radius
`r`, and each line is `a*x+b*y+c=0`. The bounds are `cx,cy` in `[-1000,1000]`,
`r` in `0..1000`, `Q` in `0..32`, `a,b` in `[-100,100]` and not both zero, and
`c` in `[-200000,200000]`. Exact input length is `4+3Q`; maximum valid and
parseable lengths are 100 and 101 signed 64-bit words. Invalid input returns
`-1`.

Successful calls write one signed 64-bit little-endian count per line, in input
order, and return the byte count. Counts are 0, 1, or 2; maximum output is 256
bytes. Null or insufficient output capacity for a nonempty result returns `-2`
without writing. A valid `Q=0` call succeeds with zero output bytes. The
workspace capacity recorded for the runner is 256 bytes.

Translate each line relative to the circle center, giving offset
`k=a*cx+b*cy+c`. The primary ports compare
`D=r²(a²+b²)-k²`: positive means two intersections, zero means tangency, and
negative means no intersection. Bounds keep every intermediate in signed
64-bit range. This takes `O(Q)` time and `O(Q)` staged output space. The
independent oracle substitutes a parameterized line into the circle equation,
then checks the resulting quadratic discriminant, with a separate vertical
line branch.

## Distinctness and provenance

[`circle`](../../c/circle/README.md) computes area and perimeter;
[`line_intersection`](../../l/line_intersection/README.md) intersects two
lines or segments; [`smallest_circle`](../../s/smallest_circle/README.md)
encloses a point set. None classifies a circle against a supplied line. The
nearby `common_tangents_two_circles` candidate treats two-circle tangent lines
and has a different operation and geometry.

The geometric construction and distance classification are described in
[CP-Algorithms, “Circle-Line Intersection”](https://cp-algorithms.com/geometry/circle-line-intersection.html),
licensed under CC BY-SA 4.0. This package uses the high-level description only;
the exact integer count contract, workload, discriminant verifier, and ports
are clean-room work. See [`RIGHTS.md`](RIGHTS.md), [`workload.json`](workload.json),
the [primary oracle](../../circle_line_intersection_count_oracle.py), the
[independent verifier](../../circle_line_intersection_count_verifier_oracle.py),
and the [static inventory checker](../../check_circle_line_intersection_count_package.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/c/circle_line_intersection_count.c`](../../../c/c/circle_line_intersection_count.c) |
| C3 | [`c3/c/circle_line_intersection_count.c3`](../../../c3/c/circle_line_intersection_count.c3) |
| C++ | [`cpp/c/circle_line_intersection_count.cpp`](../../../cpp/c/circle_line_intersection_count.cpp) |
| Elisa | [`elisa/c/circle_line_intersection_count.elisa`](../../../elisa/c/circle_line_intersection_count.elisa) |
| Mojo | [`mojo/c/circle_line_intersection_count.mojo`](../../../mojo/c/circle_line_intersection_count.mojo) |
| Nim | [`nim/c/circle_line_intersection_count.nim`](../../../nim/c/circle_line_intersection_count.nim) |
| Odin | [`odin/c/circle_line_intersection_count.odin`](../../../odin/c/circle_line_intersection_count.odin) |
| Rust | [`rust/c/circle_line_intersection_count.rs`](../../../rust/c/circle_line_intersection_count.rs) |
| V | [`v/c/circle_line_intersection_count.v`](../../../v/c/circle_line_intersection_count.v) |
| Zig | [`zig/c/circle_line_intersection_count.zig`](../../../zig/c/circle_line_intersection_count.zig) |
