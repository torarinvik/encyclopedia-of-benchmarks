# Max points on a line

Given a bounded set of distinct integer points in the plane, return the largest
number that lie on one infinite straight line.

## Contract

The exported scalar ABI symbol is `max_points_on_a_line`. Input is
`[n,x0,y0,...,x_(n-1),y_(n-1)]`, where `1<=n<=16` and both coordinates lie in
`[-100,100]`. Points must be pairwise distinct. The exact frame length is
`1+2*n`; one trailing word is admitted only as a malformed-framing probe.
Null, malformed, duplicate-point, or out-of-domain input returns `-1`.

The maximum valid frame is 33 words and the maximum parseable frame is 34
words. A one-point frame returns 1; otherwise valid results range from 2 to n.

## Algorithms

For each point as an anchor, the primary computes every direction to another
point, divides the coordinate differences by their positive gcd, and
canonicalizes the sign so opposite vectors share one direction key. The largest
direction bucket plus its anchor gives the largest line through that anchor.
The ports use a bounded open-addressed table with at most `n-1` entries. The
expected cost is `O(n^2 log C)` including Euclidean gcd, with `O(n)` temporary
storage; linear probing has an `O(n^3+n^2 log C)` worst case. Here `C` bounds
coordinate differences.

The independent oracle defines a candidate line from every point pair and
counts all input points by exact cross-product equality. It does not normalize
directions or use hash buckets; its bounded complexity is `O(n^3)`.

## Distinctness and provenance

`points_are_collinear_3d` is a boolean predicate for one supplied set in three
dimensions. `line_intersection` compares two line equations, while
`line_segment_intersection` decides whether two finite segments meet. None
returns the maximum collinear subset of a planar point set. The algorithm idea
and broad problem statement come from [LeetCode 149](https://leetcode.com/problems/max-points-on-a-line/).
The integer-line normalization follows [CP-Algorithms, “Finding the equation
of a line for a segment”](https://cp-algorithms.com/geometry/segment-to-line.html).
Only algorithm descriptions are used; this package contains independent
implementations and fixtures.

See [`RIGHTS.md`](RIGHTS.md), [`workload.json`](workload.json), the primary and
independent oracle modules, and [`check_inventory.py`](check_inventory.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/m/max_points_on_a_line.c`](../../../c/m/max_points_on_a_line.c) |
| C3 | [`c3/m/max_points_on_a_line.c3`](../../../c3/m/max_points_on_a_line.c3) |
| C++ | [`cpp/m/max_points_on_a_line.cpp`](../../../cpp/m/max_points_on_a_line.cpp) |
| Elisa | [`elisa/m/max_points_on_a_line.elisa`](../../../elisa/m/max_points_on_a_line.elisa) |
| Mojo | [`mojo/m/max_points_on_a_line.mojo`](../../../mojo/m/max_points_on_a_line.mojo) |
| Nim | [`nim/m/max_points_on_a_line.nim`](../../../nim/m/max_points_on_a_line.nim) |
| Odin | [`odin/m/max_points_on_a_line.odin`](../../../odin/m/max_points_on_a_line.odin) |
| Rust | [`rust/m/max_points_on_a_line.rs`](../../../rust/m/max_points_on_a_line.rs) |
| V | [`v/m/max_points_on_a_line.v`](../../../v/m/max_points_on_a_line.v) |
| Zig | [`zig/m/max_points_on_a_line.zig`](../../../zig/m/max_points_on_a_line.zig) |
