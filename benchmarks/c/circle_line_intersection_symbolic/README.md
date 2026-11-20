# Circle-line intersection with symbolic coordinates

Construct the intersections of an integer circle and an infinite integer line.
Unlike `circle_line_intersection_count`, this profile computes coordinates.
The `i64_array_bytes_output` input is `[cx,cy,r,a,b,c]`, describing
`(x-cx)^2+(y-cy)^2=r^2` and `a*x+b*y+c=0`. Coordinates, line coefficients
and constant lie in `[-1000,1000]`, `1<=r<=1000`, and `(a,b)` is nonzero.
The frame has exactly six words, with seven accepted for parsing before
rejection. Null or malformed input returns -1.

Let `d=a*a+b*b`, `q=a*cx+b*cy+c`, and `h=r*r*d-q*q`. If `h<0`, output
the single little-endian i64 word `[0]`. Otherwise output seven little-endian
i64 words `[k, fx, fy, d, vx, vy, h]`, where `k` is 1 when `h=0` and 2
otherwise, `fx=cx*d-a*q`, `fy=cy*d-b*q`, `vx=-b`, and `vy=a`. The points
are `(fx,fy)/d ± (vx,vy)*sqrt(h)/d`; the two coincide for `h=0`. This
representation deliberately preserves the input line's scale and orientation.
The output is at most 56 bytes. A null or insufficient output buffer returns
-2 after input validation, with no writes. Intermediate values fit in i64 for
the stated bounds: `d<=2,000,000`, `|q|<=2,001,000`, and both `r²*d`
and `q²` are below 4.01×10¹². The projection numerators have magnitude below
4.01×10⁹. Time and space are O(1).

The projection-foot construction is described by [CP-Algorithms](https://cp-algorithms.com/geometry/circle-line-intersection.html)
(CC BY-SA 4.0). Only mathematical ideas are used; the contract and code are
independently written. The reference specifies the symbolic result directly;
the independent verifier derives it by substituting a line parameter into the
circle equation. Ten language ports, workload, package checker, and suite
wiring are drafted. The workload includes opposite orientations of a slanted
line and an out-of-range signed minimum. No code or checks have been run.
