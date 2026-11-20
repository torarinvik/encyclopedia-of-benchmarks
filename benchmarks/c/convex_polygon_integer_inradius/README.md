# Integer inradius of a bounded convex region

Find the largest integer radius of a closed disk contained in the intersection
of supplied half-planes and the square `[-256,256]²`. The `i64_array_scalar`
frame is `[N,(a,b,c)*N]`, with `0<=N<=12`, `a,b` in `[-15,15]`, `c` in
`[-128,128]`, a nonzero normal with `gcd(|a|,|b|)=1`, and integer normal
length `sqrt(a²+b²)`. Exactly `1+3N` words are valid, at most 37; the
parseable cap is 38. A null or malformed input returns -1. If the original
region is empty, return -2; otherwise return the largest radius in `0..256`.
An input region that is only a point or segment is nonempty and has radius 0.

For candidate radius `r`, offset `a*x+b*y<=c` to
`a*x+b*y<=c-r*sqrt(a²+b²)` and each implicit square side inward by `r`.
Binary-search `r`, using a half-plane feasibility algorithm that accepts
lower-dimensional intersections. The integer-normal restriction keeps every
offset and predicate exact. The intended implementation sorts line angles
once and performs bounded half-plane feasibility in O(N log N + N log 257)
time and O(N) space. Degenerate intersections must not be discarded simply
because their area is zero. The independent reference enumerates boundary
intersections and tests feasibility, including degenerate regions.

The existing half-plane polygon-output helper maps both empty and zero-area
regions to an empty vertex list, so it cannot be used as the feasibility
predicate unchanged. The implementation must preserve or separately resolve
point and segment intersections. At radius 256 the implicit square itself
collapses to a point, so that boundary case is required even for `N=0`.

An exact way to use a positive-area half-plane predicate is to test radius
`r-1/32768` instead of `r`. In the three-variable linear program maximizing
radius, every vertex denominator divides a 3×3 determinant whose first two
columns have magnitude at most 15 and whose radius column has magnitude at
most 21; expansion gives a denominator bound of 28,350.
The optimum is bounded above by the implicit square. Consequently an optimum
strictly below integer `r` is at least `1/28350` below it, while any feasible
center at `r` has strict slack for every boundary at `r-1/32768`. The shifted
radius cannot itself equal an optimum, since its reduced denominator 32768
exceeds the determinant bound. Multiplying offsets by 32768 keeps this test
integral. This handles exact point and segment optima without an epsilon based
on floating-point rounding. All ten language drafts use this reduction; they are unverified.

For the scaled predicate, each shifted offset has magnitude at most
`128*32768 + (256*32768+1)*21`, below 181 million; the square's offset is
smaller. Each intersection numerator is therefore below 5.5 billion in
magnitude, and each side comparison remains below 173 billion. These
conservative bounds fit signed 64-bit arithmetic without rational reduction.

The [CP-Algorithms half-plane article](https://cp-algorithms.com/geometry/halfplane-intersection.html)
describes searching the inscribed radius by offsetting boundaries. It is
CC BY-SA 4.0; this package uses only mathematical ideas. The contract and
reference, workload, ten implementations, checker, and scalar-suite wiring are
drafted. Verifier source includes mixed-direction inputs and reversed input
orders, duplicate direction constraints, and exact and just-below strip
boundaries. No code or checks have been run.
