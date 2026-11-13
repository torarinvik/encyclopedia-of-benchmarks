# Convex-polygon minimax-length triangulation

Given a strictly convex polygon, find a triangulation whose longest edge is as
short as possible. The benchmark reports the squared length of that longest
edge, so all comparisons use exact integer arithmetic.

## Contract

The scalar symbol is `convex_polygon_minimax_length_triangulation`. Input is
`[N, x0, y0, ..., x(N-1), y(N-1)]`, where `3 <= N <= 12`, each coordinate is an
integer in `[-1000,1000]`, and vertices are supplied in strict convex boundary
order. Either clockwise or counterclockwise order is accepted. Repeated points,
collinear triples, nonconvex order, malformed length, and out-of-range values
return `-1`.

The objective includes every polygon boundary edge and each selected diagonal.
For an edge `(i,j)`, its score is `(xi-xj)^2 + (yi-yj)^2`. The result is the
minimum, over all triangulations, of the maximum edge score. The maximum valid
input length is 25 i64 values; the maximum parseable length is 26.

The primary uses an interval minimax recurrence: each interval is split at a
middle vertex, and the score combines both subinterval scores with the closing
edge. The independent verifier enumerates all triangulations recursively and
evaluates their edge sets. The profile is restricted to convex-position input;
it does not claim the general-point-set quadratic algorithm cited by the book.

## Provenance and rights

This benchmark covers the min-max-length objective in Tiow-Seng Tan,
“Optimal Triangulation,” *Encyclopedia of Algorithms*, DOI
[10.1007/978-1-4939-2864-4_715](https://doi.org/10.1007/978-1-4939-2864-4_715).
The chapter is copyrighted by Springer. This package uses the problem objective
and high-level triangulation description only; its bounded contract, recurrence
profile, workload, oracles, and ports are independently authored. See
[`RIGHTS.md`](RIGHTS.md), [`workload.json`](workload.json), the [primary oracle](../../convex_polygon_minimax_length_triangulation_oracle.py),
the [independent verifier](../../convex_polygon_minimax_length_triangulation_verifier_oracle.py),
and the [static inventory checker](../../check_convex_polygon_minimax_length_triangulation_package.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/c/convex_polygon_minimax_length_triangulation.c`](../../../c/c/convex_polygon_minimax_length_triangulation.c) |
| C3 | [`c3/c/convex_polygon_minimax_length_triangulation.c3`](../../../c3/c/convex_polygon_minimax_length_triangulation.c3) |
| C++ | [`cpp/c/convex_polygon_minimax_length_triangulation.cpp`](../../../cpp/c/convex_polygon_minimax_length_triangulation.cpp) |
| Elisa | [`elisa/c/convex_polygon_minimax_length_triangulation.elisa`](../../../elisa/c/convex_polygon_minimax_length_triangulation.elisa) |
| Mojo | [`mojo/c/convex_polygon_minimax_length_triangulation.mojo`](../../../mojo/c/convex_polygon_minimax_length_triangulation.mojo) |
| Nim | [`nim/c/convex_polygon_minimax_length_triangulation.nim`](../../../nim/c/convex_polygon_minimax_length_triangulation.nim) |
| Odin | [`odin/c/convex_polygon_minimax_length_triangulation.odin`](../../../odin/c/convex_polygon_minimax_length_triangulation.odin) |
| Rust | [`rust/c/convex_polygon_minimax_length_triangulation.rs`](../../../rust/c/convex_polygon_minimax_length_triangulation.rs) |
| V | [`v/c/convex_polygon_minimax_length_triangulation.v`](../../../v/c/convex_polygon_minimax_length_triangulation.v) |
| Zig | [`zig/c/convex_polygon_minimax_length_triangulation.zig`](../../../zig/c/convex_polygon_minimax_length_triangulation.zig) |
