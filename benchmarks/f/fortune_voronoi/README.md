# Fortune-sweep Voronoi cells

`fortune_voronoi` builds the 2D Voronoi diagram for a small set of integer sites. The core is a Fortune sweep: site events split a linked beachline, and circle events remove arcs and add Delaunay-neighbor pairs. A bounded clipping pass then intersects each site's cell with the square `[-16,16] × [-16,16]`, using only the neighbor pairs produced by the sweep.

## Contract

Input is a signed 64-bit vector `[site_count, x0, y0, ...]`. `site_count` is in `[1,8]`; each coordinate is in `[-8,8]`. Sites must be unique and have distinct y-coordinates. The bounded profile also requires no three collinear sites, no four cocircular sites, no simultaneous circle events, and no site event tied with a circle event. These general-position conditions avoid ambiguous event ordering. Ports reject malformed vectors, duplicate sites, repeated y-coordinates, collinear triples, and cocircular quadruples; the event-tie conditions remain input preconditions.

The output vector begins with the site count. For each site in input order it contains `[site_index, vertex_count]`, followed by each clipped polygon vertex as `[x_numerator, x_denominator, y_numerator, y_denominator]`. Fractions are reduced and denominators are positive. Vertices are counter-clockwise, beginning at the lexicographically smallest exact `(x,y)` coordinate. All values are serialized as little-endian signed 64-bit integers. The function returns the output byte length, `-1` for malformed or out-of-profile input, and `-2` for a null or undersized output buffer; errors leave the output untouched.

The output workspace is sized for the bounded profile. The sweep is deliberately bounded to eight sites; the linear beachline scan and event rescan keep the implementation compact while retaining Fortune's site/circle event structure.

## Source and license

The sweep and diagram representation are based on Mathias Westerdahl's `JCash/voronoi` implementation, pinned at [`28bcb7b5d7c1bb0f1a74e97f233c67afb5b48179`](https://github.com/JCash/voronoi/tree/28bcb7b5d7c1bb0f1a74e97f233c67afb5b48179). Its README identifies Fortune's sweep algorithm, and its `LICENSE` grants use, modification, and redistribution under the MIT terms. The full upstream notice is retained in [LICENSE.txt](LICENSE.txt). This package uses a bounded linked-list beachline and exact rational clipping/canonicalization to make outputs comparable across the nine language ports.

## Measurement profile

The benchmark ABI is `i64_array_bytes_output`. The bounded workload fixtures cover one-site, two-site, triangular, and four-site diagrams. The upstream `jc_voronoi` library supports much larger inputs; this package intentionally limits the profile for portable static-array implementations.
