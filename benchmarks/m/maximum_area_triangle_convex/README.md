# Maximum-area triangle in a convex polygon

For a strictly convex polygon given in counterclockwise vertex order, return
twice the largest area of a triangle formed from its vertices. This differs
from [`triangle`](../../t/triangle/README.md), which calculates properties of
one supplied triangle, and from [`rotating_calipers`](../../r/rotating_calipers/README.md),
which finds a polygon's diameter.

The proposed `i64_array_scalar` input is `[n, x0, y0, ..., x(n-1), y(n-1)]`.
There are 3 to 1024 vertices and each coordinate is in `[-1000000, 1000000]`.
The polygon must be strictly convex and counterclockwise, with every other
vertex strictly to the left of every directed edge. Invalid input returns -1.
Twice the triangle area is an integer, bounded by 8000000000000, and fits i64.

For each pair of vertices `i < j`, search the remaining counterclockwise arc
`j < k < n` for its maximum signed distance from the line through `i` and
`j`. Convexity makes the cross-product values on that arc unimodal, permitting
binary search using neighboring values. Enumerating all bases costs
O(n² log n); validating each edge against all vertices costs O(n²), and the
working space beyond the input is O(1). This avoids assuming that a single
three-pointer sweep always finds the global optimum.

The [Library Checker proposal](https://github.com/yosupo06/library-checker-problems/issues/1397)
is an idea index. [Keikha et al.](https://arxiv.org/abs/1705.11035) discuss
the problem and a counterexample to a previously proposed shortcut. The
contract, search, and exhaustive reference here are independently written;
no external code, problem text, or examples are copied.

Reserved and in progress: all ten language sources and an exhaustive reference
are drafted, alongside initial fixtures, a package validator and scalar-suite
registration. Fixtures include rotated input, tied maxima, coordinate bounds,
self-intersection, repeated vertices, malformed frames, and null inputs. The
verifier also describes rotated convex chains compared against exhaustive
enumeration. Nothing has been compiled or executed; correctness and compiler
compatibility remain unverified.
