# All farthest neighbors on a convex polygon

For each vertex of a clockwise strictly convex polygon, return one farthest
vertex. This differs from [`rotating_calipers`](../../r/rotating_calipers/README.md),
which emits only the global diameter, and from
[`smawk_row_minima`](../../s/smawk_row_minima/README.md), which searches an
explicit matrix rather than constructing geometric comparison values on demand.

The draft ABI is `i64_array_bytes_output`, input `[n,x0,y0,...]` with 3–64
vertices and integer coordinates in `[-1000000,1000000]`. The caller promises
the points are the clockwise vertices of a simple strictly convex polygon;
the implementation checks bounds, framing, and strictly clockwise consecutive
turns, but does not prove simplicity. This promise preserves the linear-time
algorithm. Each output word is a little-endian signed i64 vertex index; ties
select the first farthest vertex encountered clockwise after the query vertex.
Invalid framing, null input, or a failed checked condition returns `-1`; null
or insufficient output returns `-2`, with no writes on error. Maximum input is
129 words and maximum output is 512 bytes.

The algorithm applies SMAWK row-maxima search to an implicit `n` by `2n-1`
matrix: the forward cyclic interval holds squared vertex distances, with
ordered sentinel values outside it. This gives O(n) comparisons and O(n)
working storage, including local turn checks. The exact arithmetic fits i64
under the coordinate bound. A direct all-pairs scan is used for the independent
reference, and makes no unimodality assumption about distances around a polygon.

Source: Aggarwal, Klawe, Moran, Shor, and Wilber, [Geometric Applications of a
Matrix-Searching Algorithm](https://doi.org/10.1007/BF01840359), 1987. Only
the mathematical construction and algorithm were consulted; code and fixtures
are independently authored. The task catalog supplies the per-vertex operation
idea; this package chooses an explicit deterministic cyclic tie rule.

Status: all ten language drafts, a direct reference, a workload, and byte-output
suite registration are present. Verifier source includes a maximum-size convex
polygon, rotations, tie, malformed-input, and buffer cases. No code has been
compiled or run.
