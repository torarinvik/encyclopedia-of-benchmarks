# Half-plane intersection by incremental polygon clipping

Construct the feasible polygon of bounded closed half-planes by starting with
the fixed square and clipping the current convex polygon once for each input
constraint, in input order. This differs computationally from the existing
[`half_plane_intersection`](../half_plane_intersection/README.md), which sorts
normal directions and prunes a deque.

The `i64_array_bytes_output` input is `[N,(a,b,c)*N]`, denoting
`a*x+b*y<=c`, with `0<=N<=12`, `-16<=a,b<=16`, `-128<=c<=128`, and
`gcd(abs(a),abs(b))=1`. The implicit square is `[-256,256]²`. Input has
exactly `1+3*N` words, at most 37 valid and 38 parseable. Null or malformed
input returns -1. The output is little-endian i64 words
`[V,(x_num,x_den,y_num,y_den)*V]`: reduced fractions with positive
denominators, counterclockwise order starting at the minimum `(y,x)`. Empty or
zero-area intersections output only `[0]`; otherwise at most 16 vertices are
output. A null or insufficient output buffer returns -2 after input
validation, without writes. Maximum output is 520 bytes.

Each clipping pass scans the polygon edges, retaining inside vertices and
inserting intersections when an edge crosses the new boundary. This is the
same sequential clipping kernel named Sutherland–Hodgman when the half-planes
come from a convex clipping window; the RosettaCodeData title therefore maps
to this package rather than a second benchmark. The local contract starts from
an implicit bounding square and emits exact rational vertices, while the task
title emphasizes a subject/window pair and area output. Implementations
must use exact rational predicates, preserve the supporting input line for
each edge so new intersections are between original boundaries, and remove
duplicate and collinear output vertices before canonicalizing. With at most
N+4 polygon edges, clipping takes O(N²) time and O(N) space. The independent
reference enumerates feasible pairwise line intersections and builds a convex
hull; it is shared with the sorted-deque package, whose output contract is
identical.

The C draft collapses zero-area intermediate regions immediately: subsequent
intersections cannot regain positive area, which avoids ill-defined line
intersections after the polygon has collapsed to a segment or point.

The [CP-Algorithms half-plane article](https://cp-algorithms.com/geometry/halfplane-intersection.html)
describes incremental clipping as a separate method. The RosettaCodeData
[popular-task index](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks)
also lists Sutherland–Hodgman polygon clipping; its method description is
Sutherland and Hodgman's 1974 paper,
[DOI 10.1145/360767.360802](https://doi.org/10.1145/360767.360802). These sources
are used for algorithm ideas and title discovery only. The CP-Algorithms
article is CC BY-SA 4.0; no source code or prose is reused. The contract, code,
and fixtures are independently authored.

Status: contract, independent reference adapter, ten language ports, workload,
package checker, and byte-output suite integration are drafted. No programs or
checks have been run; all remain unverified.

The shared verifier is also wired to generate bounded constraints and compare
each port with the independent pair-intersection oracle. Its checks have not
been executed.
