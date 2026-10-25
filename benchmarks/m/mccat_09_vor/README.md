# McCat 09-vor hull-contraction Voronoi core

This package captures the bounded geometric core of McCat 09-vor. It starts from the convex hull of integer sites, repeatedly removes the hull vertex with the highest local circumradius priority (using the source's signed cosine-squared secondary key), then reports the enclosing circle for the final three sites. The source also builds and draws Voronoi edges; that screen-oriented graph construction and launcher text are outside this scalar core.

## Contract

The `i64_array_scalar` entry point is `mccat_09_vor`. Input is `[site_count, x0, y0, ...]`; `site_count` is 3 through 8 and each coordinate is an integer in `[-4, 4]`. Input length must be exactly `1 + 2*site_count`. Duplicate sites and any input containing a collinear triple are rejected. During a contraction, a case whose source priority keys tie is also rejected because the original splay ordering uses insertion-order details that the bounded contract does not model.

The convex hull is built in counterclockwise order, with collinear hull points omitted. Interior sites do not participate in the contraction, matching the source's hull-only construction. At each step the maximum circumradius-squared key is removed; equal radius keys use the smaller signed cosine-squared angle. The remaining three sites produce the source's final circle: the circumcircle for an acute/right triangle, and the minimum enclosing circle with diameter on the longest side for an obtuse triangle. The center coordinates are truncated toward zero and the radius is rounded to hundredths (ties upward).

The result encodes `(center_x, center_y, radius_cents)` as `(((center_x + 1024) * 2049 + (center_y + 1024)) * 200000 + radius_cents)`. Invalid inputs or unencodable outputs return `-1`. The profile keeps all intermediate geometry small and the maximum input length is 17 signed 64-bit words.

## Relationship to local packages

This is not another port of the local Fortune sweep (`fortune_voronoi`), Olden quad-edge divide-and-conquer (`olden_voronoi`), or Bowyer-Watson (`delaunay_triangulation`) algorithms. It uses the McCat hull-vertex contraction priority process and exposes its final three-site circle; it does not return a complete Voronoi diagram. Those packages share the broad computational-geometry topic but not the core algorithm or live-out.

## Pinned source and license

Source: [`McCat/09-vor`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McCat/09-vor) at `lac-dcc/Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The source launcher `info.sh` compiles `vor.c`, `ch.c`, `intersec.c`, `pointlis.c`, `splay.c`, and `splay2.c` with `-lm`; its sample input is `vor.in3`. The source files carry a 1996 McGill University, McCAT System Group, and ACAPS Benchmark Administrator notice that permits redistribution and modification if the notice is maintained. The complete notice is preserved in [LICENSE_NOTICE.txt](LICENSE_NOTICE.txt) and in all nine language ports. The ports are independent implementations of the bounded contract, not copied source files.

See [workload.json](workload.json) and the independent [Python oracle](../../mccat_09_vor_oracle.py).
