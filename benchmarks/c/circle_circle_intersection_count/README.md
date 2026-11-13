# Circle-circle intersection count

Classify the shared circumference of two circles using exact integer
arithmetic. The result is the number of distinct intersection points, with a
separate value for coincident circles.

## Distinction from local circle packages

[`circle_line_intersection_count`](../circle_line_intersection_count/README.md)
classifies a supplied line against one circle. It does not derive a line from
two circles. [`common_tangents_two_circles`](../common_tangents_two_circles/README.md)
counts common tangent lines, not points where the circumferences intersect.
This benchmark subtracts two circle equations to construct their radical axis,
then classifies where that axis meets the first circle. It explicitly handles
the coincident-center case.

## Contract

The `i64_array_scalar` ABI symbol is `circle_circle_intersection_count`. Input
is exactly `[x1,y1,r1,x2,y2,r2]`, with center coordinates in `[-1000,1000]` and
radii in `[1,1000]`. The valid input length is 6; the parser bound is 7 to
admit a trailing-word framing probe. Null input, malformed length, and values
outside the profile return `-1`.

The result values are:

- `0`: disjoint circumferences, including strict containment.
- `1`: one tangent point, external or internal.
- `2`: two distinct intersection points.
- `3`: coincident circles, which share infinitely many points.

The primary algorithm translates the first center to the origin and subtracts
the circle equations to obtain the radical-axis coefficients
`A=-2*dx`, `B=-2*dy`, and `C=dx^2+dy^2+r1^2-r2^2`. For distinct centers, the
exact discriminant `D=r1^2*(A^2+B^2)-C^2` determines whether the line misses,
touches, or crosses the first circle. Equal centers are handled separately:
equal radii return 3, and unequal radii return 0. The independent oracle uses
only squared-distance comparisons against `(r1+r2)^2` and `|r1-r2|^2`.

The coordinate and radius bounds keep all primary discriminant intermediates
within signed 64-bit range. Both methods take O(1) time and use O(1) auxiliary
space.
[`workload.json`](workload.json) covers external/internal tangency, secants,
disjointness, containment, coincident and concentric circles, translated
coordinates, malformed framing, and range errors.
[`verify_circle_circle_intersection_count_package.py`](verify_circle_circle_intersection_count_package.py)
performs only static fixture/oracle and source-inventory checks; the package
ports have not been run.

## Provenance

The radical-axis reduction is described in CP-Algorithms, [Circle-Circle
Intersection](https://cp-algorithms.com/geometry/circle-circle-intersection.html),
licensed under CC BY-SA 4.0. This package uses the mathematical description
only. Implementations, workload, and exact category oracle are clean-room; see
[`RIGHTS.md`](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [`c/c/circle_circle_intersection_count.c`](../../../c/circle_circle_intersection_count.c) |
| C3 | [`c3/c/circle_circle_intersection_count.c3`](../../../c3/circle_circle_intersection_count.c3) |
| C++ | [`cpp/c/circle_circle_intersection_count.cpp`](../../../cpp/c/circle_circle_intersection_count.cpp) |
| Elisa | [`elisa/c/circle_circle_intersection_count.elisa`](../../../elisa/c/circle_circle_intersection_count.elisa) |
| Mojo | [`mojo/c/circle_circle_intersection_count.mojo`](../../../mojo/c/circle_circle_intersection_count.mojo) |
| Nim | [`nim/c/circle_circle_intersection_count.nim`](../../../nim/c/circle_circle_intersection_count.nim) |
| Odin | [`odin/c/circle_circle_intersection_count.odin`](../../../odin/c/circle_circle_intersection_count.odin) |
| Rust | [`rust/c/circle_circle_intersection_count.rs`](../../../rust/c/circle_circle_intersection_count.rs) |
| V | [`v/c/circle_circle_intersection_count.v`](../../../v/c/circle_circle_intersection_count.v) |
| Zig | [`zig/c/circle_circle_intersection_count.zig`](../../../zig/c/circle_circle_intersection_count.zig) |
