# Symbolic circle-circle intersection

Construct the common points of two circles with exact integer-radical
coordinates. The `i64_array_bytes_output` input `[x1,y1,r1,x2,y2,r2]`
contains centers in `[-1000,1000]` and radii in `[1,1000]`. Exactly six
words are valid; seven may be parsed before rejection. Malformed or null
input returns -1.

When centers coincide, output `[3]` if the radii agree (infinitely many
intersections), otherwise `[0]`. For distinct centers, let `dx=x2-x1`,
`dy=y2-y1`, `d=dx²+dy²`, `t=d+r1²-r2²`, and `h=4*r1²*d-t²`. If `h<0`,
output `[0]`. Otherwise output `[k,fx,fy,den,vx,vy,h]`, where `k=1` for
`h=0` and `2` otherwise; `den=2*d`, `fx=den*x1+dx*t`,
`fy=den*y1+dy*t`, `vx=-dy`, and `vy=dx`. Coordinates are
`(fx,fy)/den ± (vx,vy)*sqrt(h)/den`. All words are signed little-endian i64;
the maximum output is 56 bytes. A null or insufficient output returns -2
after validation without writes. Here `d<=8,000,000`, `|t|<=9,000,000`,
`4*r1²*d<=32,000,000,000,000`, and `t²<=81,000,000,000,000`; projection
numerators have magnitude at most 34,000,000,000. Thus all intermediate
arithmetic fits i64. Time and space are O(1).

This differs from the existing count-only profile and from supplied-line
intersection. The reduction to a radical axis is described by
[CP-Algorithms](https://cp-algorithms.com/geometry/circle-circle-intersection.html)
(CC BY-SA 4.0); the contract and implementations use mathematical ideas only.
Ten language ports, a factored-distance independent verifier, workload,
checker, and suite wiring are drafted. The verifier specifies cases around
both tangency thresholds, along both coordinate axes, as well as reversed
circle order and coincident centers. Nothing has been executed.
