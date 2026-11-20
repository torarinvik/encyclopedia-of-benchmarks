# Convex polygon minimum-weight triangulation

This profile minimizes the total supplied weight of the internal diagonals in a
triangulation of a convex polygon. The vertices are implicit labels `0..n-1` in
counterclockwise cyclic order. Every internal chord is legal, and the workload
supplies a nonnegative integer weight for each one. It isolates the chapter's
additive interval DP: no coordinates, Euclidean lengths, or geometric
predicates are part of the input or measured operation.

## Contract

The exported `i64_array_scalar` symbol is
`convex_polygon_minimum_weight_triangulation`. Input is
`[n,w_(i,j),...]`, with `3<=n<=10`. The weights follow lexicographic order of
`(i,j)` for `0<=i<j<n`, `j>=i+2`, excluding the hull edge `(0,n-1)`. Thus the
number of weights is `n(n-3)/2`, and the exact frame length is
`1+n(n-3)/2` (maximum 36 words; 37 words are accepted for explicit trailing
data rejection). Each weight is in `0..1000`. The result is the minimum sum of
the `n-3` diagonals in a triangulation, between 0 and 7,000. Invalid or null
input returns `-1`.

The primary uses the interval recurrence. `dp[i,j]` excludes its boundary
chord `(i,j)`. For each split `k`, it combines `dp[i,k]` and `dp[k,j]` and adds
the weights of `(i,k)` and `(k,j)` when those are internal diagonals of the
original polygon. The parent charges its child boundary chords once, while
adjacent edges and the outer hull edge have weight zero, so every selected
diagonal is counted exactly once. The recurrence takes `O(n^3)` time and
`O(n^2)` space. The independent oracle enumerates all Catalan triangulations,
forms each complete diagonal set, and scores that set directly. Since only the
optimal scalar is returned, equal-cost triangulations need no tie policy.

The valid input length is at most 36 words, the parseable length is 37 words,
the result is at most 7,000, and declared fixed workspace is 2,048 bytes.
The workload includes `n=10` zero-cost and maximum-cost cases, plus malformed
frames and a pentagon with a nonlocal optimum choice.

The ten language ports are registered in the shared `i64_array_scalar`
runner and verifier.

## Distinctness and provenance

Chapter 715 also appears in local convex-polygon benchmarks for bottleneck
objectives: [`convex_polygon_minimax_length_triangulation`](../convex_polygon_minimax_length_triangulation/README.md)
minimizes the longest edge, while max-min length, angle, height, slope, and
eccentricity packages optimize different measures. This package instead
minimizes an additive sum over supplied weights. The general geometric
minimum-weight triangulation problem for arbitrary point sets is outside this
bounded convex-position profile.

The method is described in Tiow-Seng Tan, [“Optimal Triangulation,”
*Encyclopedia of Algorithms*, Chapter 715](https://doi.org/10.1007/978-1-4939-2864-4_715),
and G. T. Klincsek, [“Minimal triangulations of polygonal domains,”
*Annals of Discrete Mathematics* 9 (1980), 121–123](https://doi.org/10.1016/S0167-5060(08)70044-X).
Only the mathematical algorithm is used. The implementations, workload,
references, and documentation are clean-room; no upstream source code, prose,
or fixtures were copied. See [`RIGHTS.md`](RIGHTS.md),
[`workload.json`](workload.json), the two references, and the static inventory.

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/c/convex_polygon_minimum_weight_triangulation.c`](../../../c/c/convex_polygon_minimum_weight_triangulation.c) |
| C3 | [`c3/c/convex_polygon_minimum_weight_triangulation.c3`](../../../c3/c/convex_polygon_minimum_weight_triangulation.c3) |
| C++ | [`cpp/c/convex_polygon_minimum_weight_triangulation.cpp`](../../../cpp/c/convex_polygon_minimum_weight_triangulation.cpp) |
| Elisa | [`elisa/c/convex_polygon_minimum_weight_triangulation.elisa`](../../../elisa/c/convex_polygon_minimum_weight_triangulation.elisa) |
| Mojo | [`mojo/c/convex_polygon_minimum_weight_triangulation.mojo`](../../../mojo/c/convex_polygon_minimum_weight_triangulation.mojo) |
| Nim | [`nim/c/convex_polygon_minimum_weight_triangulation.nim`](../../../nim/c/convex_polygon_minimum_weight_triangulation.nim) |
| Odin | [`odin/c/convex_polygon_minimum_weight_triangulation.odin`](../../../odin/c/convex_polygon_minimum_weight_triangulation.odin) |
| Rust | [`rust/c/convex_polygon_minimum_weight_triangulation.rs`](../../../rust/c/convex_polygon_minimum_weight_triangulation.rs) |
| V | [`v/c/convex_polygon_minimum_weight_triangulation.v`](../../../v/c/convex_polygon_minimum_weight_triangulation.v) |
| Zig | [`zig/c/convex_polygon_minimum_weight_triangulation.zig`](../../../zig/c/convex_polygon_minimum_weight_triangulation.zig) |
