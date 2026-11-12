# Common tangents to two circles

Count the distinct lines tangent to both of two circles. The local profile uses
integer centers and nonnegative integer radii, so all feasibility checks are
exact and avoid floating-point boundary tolerances.

## Contract

The exported scalar ABI symbol is `common_tangents_two_circles`. Input is the
six-word signed 64-bit array `[x1,y1,r1,x2,y2,r2]`. Each center coordinate is
in `[-100000,100000]`, each radius is in `[0,100000]`, and the centers must be
distinct. The result is the number of distinct common tangent lines, from zero
through four. Coincident centers, including coincident circles with infinitely
many common tangents, are invalid and return `-1`. Null input, malformed
length, or values outside the profile also return `-1`. A valid input uses six
words; the parser bound is seven words to admit one trailing-word framing probe.

When both radii are positive, externally tangent circles have three distinct
lines and internally tangent circles have one. Two distinct zero-radius
circles have one common line. If exactly one radius is zero, the point-circle
pair has two tangents when the point is outside the other circle, one on its
boundary, and none inside.

## Algorithms

Translate the first center to the origin conceptually. A normalized line
`a*x+b*y+c=0` tangent to both circles has `c` equal to one signed first radius;
the second signed radius gives a second linear constraint. For each of the four
sign pairs, the remaining quadratic has discriminant

`D2 - (s2*r2 - s1*r1)^2`,

where `D2=(x2-x1)^2+(y2-y1)^2`. A nonnegative value yields a tangent family.
The primary ports count these four cases and collapse duplicate candidates at
positive-radius tangency; zero-radius cases are handled explicitly. The
independent oracle instead compares `D2` with `(r1+r2)^2` and
`(r1-r2)^2`. Both use `O(1)` time and space.

## Distinctness and provenance

[`circle`](../circle/README.md) returns area or perimeter;
[`midpoint_circle`](../../m/midpoint_circle/README.md) rasterizes a circle;
[`smallest_circle`](../../s/smallest_circle/README.md) finds an enclosing
circle; and
[`voronoi_delaunay_empty_circle`](../../v/voronoi_delaunay_empty_circle/README.md)
constructs a Delaunay graph. None counts the distinct common tangent lines of
a pair of circles.

The source is [CP-Algorithms, “Common tangents to two circles”](https://cp-algorithms.com/geometry/tangents-to-two-circles.html),
licensed under CC BY-SA 4.0. This package uses only the high-level sign-case
and discriminant description; the bounded exact contract, fixtures, threshold
oracle, and ten ports are clean-room work. No article code, tests, or prose was
copied.

See [`RIGHTS.md`](RIGHTS.md), [`workload.json`](workload.json), the
[primary oracle](../../common_tangents_two_circles_oracle.py), the
[independent oracle](../../common_tangents_two_circles_verifier_oracle.py),
and the static package checker at
[`benchmarks/check_common_tangents_two_circles_package.py`](../../check_common_tangents_two_circles_package.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/c/common_tangents_two_circles.c`](../../../c/c/common_tangents_two_circles.c) |
| C3 | [`c3/c/common_tangents_two_circles.c3`](../../../c3/c/common_tangents_two_circles.c3) |
| C++ | [`cpp/c/common_tangents_two_circles.cpp`](../../../cpp/c/common_tangents_two_circles.cpp) |
| Elisa | [`elisa/c/common_tangents_two_circles.elisa`](../../../elisa/c/common_tangents_two_circles.elisa) |
| Mojo | [`mojo/c/common_tangents_two_circles.mojo`](../../../mojo/c/common_tangents_two_circles.mojo) |
| Nim | [`nim/c/common_tangents_two_circles.nim`](../../../nim/c/common_tangents_two_circles.nim) |
| Odin | [`odin/c/common_tangents_two_circles.odin`](../../../odin/c/common_tangents_two_circles.odin) |
| Rust | [`rust/c/common_tangents_two_circles.rs`](../../../rust/c/common_tangents_two_circles.rs) |
| V | [`v/c/common_tangents_two_circles.v`](../../../v/c/common_tangents_two_circles.v) |
| Zig | [`zig/c/common_tangents_two_circles.zig`](../../../zig/c/common_tangents_two_circles.zig) |
