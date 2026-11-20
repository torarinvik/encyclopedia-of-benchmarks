# Rational polygon lattice points

This profile counts integer lattice points strictly inside a convex polygon
whose vertices share a small rational coordinate denominator. It applies an
oriented edge formula: nonvertical edges contribute sums of integer floors
over their covered x-columns. Each rational floor sum is evaluated by a
Euclidean recurrence.

## Contract

The scalar ABI and exported symbol are `i64_array_scalar` and
`rational_polygon_lattice_points`. Input is
`[S,N,(x_num,y_num)*N]`, where each vertex is `(x_num/S,y_num/S)`:

- `2<=S<=8` and `3<=N<=8`.
- Numerators lie in `[-32,32]`, and each numerator also satisfies
  `abs(numerator)<=4*S`, so physical coordinates lie in `[-4,4]`. Vertices are
  listed in strict convex order, clockwise or counterclockwise, without
  collinear boundary triples.
- At least one vertex coordinate is nonintegral. This profile is for rational
  polygons; the lattice-vertex special case is already represented by
  [`polygon_points`](../../p/polygon_points/README.md).
- The exact frame length is `2+2*N`. Malformed frames and invalid polygons
  return `-1`; valid frames return the number of strict interior integer points.

The maximum valid and parseable input lengths are 18 and 19 signed 64-bit
words. With coordinates in `[-4,4]`, the result is in `0..49`; declared
workspace is 1024 bytes.

## Algorithm and distinctness

For a directed nonvertical edge, the primary applies the line's floor sum over
integer x-values in the half-open interval from its lesser x-coordinate to its
greater x-coordinate. Every integer x column that equals a vertex x-coordinate
is excluded from all edge floor-sum spans, then classified directly at each
integer y in `[-4,4]` using exact ray crossing and boundary tests. This event
step handles vertex columns and vertical boundaries without an endpoint
correction. Left-to-right and right-to-left edge spans contribute with opposite
signs, and polygon orientation normalizes the final count. This adapts the
edge-wise rational floor-sum method from CP-Algorithms' [Lattice points inside
non-lattice polygon](https://cp-algorithms.com/geometry/lattice-points.html).

Each of `N` edge spans can split around at most `N` integer vertex-x columns,
so the Euclidean floor sums take `O(N^2 log C)` work. Direct classification of
at most `N` integer vertex-x columns checks at most nine candidate y-values per
column against `N` edges, adding bounded `O(N^2)` work. Strict-convexity
validation uses `O(N^3)` orientation checks.

The primary reference uses exact signed Euclidean floor sums. The independent
reference enumerates the small bounding box and classifies every integer point
with exact segment-boundary and ray-crossing tests. That differs from
[`polygon_points`](../../p/polygon_points/README.md), which applies Pick's
theorem to lattice polygons. Fixtures include both polygon windings, a single
integer-x vertex column, an integer-x vertical boundary, and a nonconvex input
rejected by the contract.

## Ports

| Language | Source |
|---|---|
| C | [`c/r/rational_polygon_lattice_points.c`](../../../c/rational_polygon_lattice_points.c) |
| C3 | [`c3/r/rational_polygon_lattice_points.c3`](../../../c3/r/rational_polygon_lattice_points.c3) |
| C++ | [`cpp/r/rational_polygon_lattice_points.cpp`](../../../cpp/r/rational_polygon_lattice_points.cpp) |
| Elisa | [`elisa/r/rational_polygon_lattice_points.elisa`](../../../elisa/r/rational_polygon_lattice_points.elisa) |
| Mojo | [`mojo/r/rational_polygon_lattice_points.mojo`](../../../mojo/r/rational_polygon_lattice_points.mojo) |
| Nim | [`nim/r/rational_polygon_lattice_points.nim`](../../../nim/r/rational_polygon_lattice_points.nim) |
| Odin | [`odin/r/rational_polygon_lattice_points.odin`](../../../odin/r/rational_polygon_lattice_points.odin) |
| Rust | [`rust/r/rational_polygon_lattice_points.rs`](../../../rust/r/rational_polygon_lattice_points.rs) |
| V | [`v/r/rational_polygon_lattice_points.v`](../../../v/r/rational_polygon_lattice_points.v) |
| Zig | [`zig/r/rational_polygon_lattice_points.zig`](../../../zig/r/rational_polygon_lattice_points.zig) |

See [`RIGHTS.md`](RIGHTS.md) for provenance. Sources and workloads have not
been executed or validated.
