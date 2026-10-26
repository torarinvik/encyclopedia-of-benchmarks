# Traveling salesperson with few inner points

This profile implements the first fixed-parameter algorithm from the
Encyclopedia chapter: keep the supplied convex-hull points in cyclic order,
enumerate every linear order of the interior points, and use a two-endpoint
dynamic program for each order. The best closing tour cost is returned. This is
distinct from unrestricted Held–Karp TSP and metric-TSP tree doubling.

## Input and output

Input is `[n, k, outer_ids..., inner_ids..., x0, y0, ..., x(n-1), y(n-1)]`.
The outer IDs list the vertices of the strict convex hull in cyclic order; the
remaining `k` IDs identify distinct points strictly inside it. The convex hull
and classification are supplied, as assumed by the chapter algorithm. Bounds
are `3 <= n <= 16`, `0 <= k <= min(6,n-3)`, and coordinates in `[-1000,1000]`.
The valid input length is exactly `2 + 3*n` (at most 50 values); 51 values may
be parsed to reject a trailing value at the bound. IDs must form a permutation
of `0..n-1`, and coordinates must be distinct.

To make the Euclidean objective portable through the integer ABI, each edge
length is rounded to the nearest thousandth using integer square root; exact
halfway cases round down. The DP therefore optimizes the sum of these fixed
point edge lengths. Output is that closed-tour cost as one little-endian signed
64-bit integer, in thousandths of a coordinate unit. Invalid input returns
`-1`; a null output or capacity below 8 returns `-2` without writing.

The profile uses the chapter's permutation-plus-DP algorithm. It does not
include convex-hull construction; callers must provide a valid cyclic order.
Because rounding can perturb the global Euclidean optimum, the reported value
is the optimum among tours that preserve the supplied hull cycle; the profile
does not claim an exact optimum for the unrounded Euclidean TSP. The bounded
coordinate and point-count rules keep all scaled distances and tour costs
within signed 64-bit arithmetic.

Source: *Encyclopedia of Algorithms*, “Traveling Sales Person with Few Inner
Points,” DOI [`10.1007/978-1-4939-2864-4_426`](https://doi.org/10.1007/978-1-4939-2864-4_426).
The implementation is clean-room and does not reproduce book prose or code.

| Language | Port |
|---|---|
| C | `c/t/tsp_few_inner_points.c` |
| C3 | `c3/t/tsp_few_inner_points.c3` |
| C++ | `cpp/t/tsp_few_inner_points.cpp` |
| Elisa | `elisa/t/tsp_few_inner_points.elisa` |
| Nim | `nim/t/tsp_few_inner_points.nim` |
| Odin | `odin/t/tsp_few_inner_points.odin` |
| Rust | `rust/t/tsp_few_inner_points.rs` |
| V | `v/t/tsp_few_inner_points.v` |
| Zig | `zig/t/tsp_few_inner_points.zig` |
