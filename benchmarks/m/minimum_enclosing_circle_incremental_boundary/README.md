# Incremental minimum-enclosing-circle boundary flags

Given integer points and an explicit processing permutation, construct their
minimum enclosing circle by incremental support updates and report which
original points lie on its boundary. The permutation makes the randomized
algorithm's order reproducible; this profile does not claim that supplied
orders are random.

The `i64_array_bytes_output` frame is `[n, x_0, y_0, ..., x_(n-1), y_(n-1),
order_0, ..., order_(n-1)]`, where `1<=n<=64`, coordinates are integers in
`[-100,100]`, and `order` is a permutation of `0..n-1`. Require exact length
`1+3*n`; at most 194 words are parseable. Success writes n bytes in original
point order, each 1 for a point on the minimum circle and 0 otherwise, and
returns n. Null or malformed input returns -1; a null or insufficient output
buffer returns -2 after input validation, without writes. Repeated points and
collinear sets are valid. A single distinct point has radius zero, making
every copy of that point a boundary point.

Process points in the supplied order, maintaining a circle enclosing the
prefix. When a point falls outside, rebuild with that point constrained to
the boundary; when an earlier point falls outside that circle, use those two
points as boundary support and scan still earlier points, updating the circle
with a third support when needed. Degenerate collinear supports must be
handled by the appropriate farthest-pair diameter circle. All containment
and boundary comparisons are exact rational integer comparisons, not
floating-point tolerance tests.

The bounded kernel has O(n³) worst-case time and O(n) space. With an
independent uniform permutation, the standard incremental method has O(n)
expected time; no such distribution is imposed by this benchmark. The
independent reference enumerates point, pair-diameter, and noncollinear triple
support circles and compares exact rational values, taking O(n⁴) time. The
existing [`smallest_circle`](../../s/smallest_circle/README.md) uses exhaustive
candidate enumeration and returns floating-point circle parameters; the 3D
Welzl package has a different dimensional and support-set workload.

The mathematical method is described by [CP-Algorithms](https://cp-algorithms.com/geometry/enclosing-circle.html).
The article is CC BY-SA 4.0; only mathematical ideas are used. The interface,
reference, fixtures, and ports are independently authored.

For coordinates bounded by 100, the unreduced determinant denominator is at
most 120,000 in magnitude, each center numerator at most 12,000,000, and
each scaled coordinate difference at most 24,000,000. Thus a sum of two
squares is at most 1,152,000,000,000,000, within signed 64-bit range.

Status: contract, independent reference, ten language drafts, workload,
package checker, and byte-output suite wiring are drafted. The verifier source
includes exhaustive small grids and permutations, near-collinear coordinate
extremes, and a full-size duplicate/collinear case.
Nothing has been compiled or run; all drafts remain unverified.
