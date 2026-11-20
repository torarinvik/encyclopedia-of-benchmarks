# Minimum-area rectangle from an arbitrary point set

Find the minimum-area rectangle whose four corners are selected from a set of
integer points. Rectangle sides may have any orientation. This differs from
[`minimum_area_enclosing_rectangle`](../minimum_area_enclosing_rectangle/README.md),
which encloses a convex polygon, and from the rectangle-union profiles, which
measure axis-aligned coverage.

## Contract

The exported `minimum_area_rectangle_arbitrary_orientation` function uses
`i64_array_scalar`. Input is `[n,x0,y0,...]`, with `4<=n<=16`, unique points,
coordinates in `[-32,32]`, and exact length `1+2*n`. The result is twice the
smallest area of any rectangle formed by four input points. It is zero when no
rectangle exists and `-1` for a null, malformed, duplicate-point, or
out-of-range input. The maximum valid frame is 33 words and the maximum
parseable frame is 34 words.

For every unordered pair of points, treat the pair as a candidate diagonal.
Two pairs are diagonals of a rectangle exactly when they have the same
doubled midpoint and the same squared length. Compare disjoint pairs with
matching keys and take the absolute cross product of their diagonal vectors;
this is twice the rectangle area. With at most 120 point pairs, the bounded
kernel takes `O(n^4)` time and `O(n)` auxiliary space for point coordinates.

The independent oracle enumerates all four-point subsets and cyclic orders.
It checks diagonal bisection and a right angle between adjacent sides, then
computes twice the area from the side-vector cross product.

## Sources and rights

The public [LeetCode 963 title and geometry specification](https://leetcode.com/problems/minimum-area-rectangle-ii/)
was used for discovery only. The diagonal characterization is cross-checked
against the [Hong Kong Olympiad in Informatics computational-geometry notes](https://assets.hkoi.org/training2023/geom.pdf).
No problem wording, examples, tests, code, or editorial material is reused.
See [`RIGHTS.md`](RIGHTS.md).

## Artifacts

- [`workload.json`](workload.json): bounded scalar fixtures.
- [`primary_oracle.py`](primary_oracle.py): pair-of-diagonals method.
- [`independent_oracle.py`](independent_oracle.py): four-point/cyclic-order reference.
- [`verify_workload.py`](verify_workload.py): static metadata, fixture, oracle, and port review.
- [`INVENTORY.md`](INVENTORY.md): source inventory.

Shared runner and catalog integration is maintained separately.
