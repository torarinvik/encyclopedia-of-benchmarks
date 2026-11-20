# Oriented polyhedron volume

Compute the algebraic signed volume of a closed, edge-paired oriented triangle
mesh that is already supplied. The input is a triangle soup: coordinates are
listed per face, and equal integer coordinates identify shared vertices. This
profile measures the signed sum of tetrahedra from the origin; it does not
construct a hull from a point cloud.

## Contract

- ABI: `i64_array_bytes_output`; exported symbol: `polyhedron_volume`.
- Input is `[F, ax,ay,az,bx,by,bz,cx,cy,cz, ...]`, with `4<=F<=32` and each
  coordinate in `[-50,50]`. Each triangle must have three non-collinear
  vertices.
- The oriented edge rule is exact: every directed triangle edge must occur
  once, and the same geometric edge in reverse direction must occur once.
  This enforces a closed, consistently oriented edge-paired surface. Disjoint
  components are allowed and their signed contributions add. Self-intersecting
  surfaces are also admitted; the result is their algebraic winding-weighted
  volume, not the volume of the geometric union. No further vertex-link or
  embedding test is made.
- The exact input length is `1+9*F`; the maximum valid frame has 289 signed
  64-bit values and 290 are parseable to reject a trailing word. Invalid input
  returns `-1`.
- For every oriented face `(a,b,c)`, add `det(a,b,c)=a·(b×c)`. Divide the sum
  by 6 to obtain signed volume, multiply by 1,000,000, and round to nearest
  integer with exact ties away from zero. Success writes that signed i64 in
  little-endian order and returns 8.
- After full input validation, null output or capacity below 8 returns `-2`
  and writes nothing. Invalid input takes precedence over output-buffer errors.

The primary validates edge pairing by searching for the one same-direction
and one reverse-direction occurrence of every directed edge, then sums signed
tetrahedral determinants. Validation is `O(F^2)` and the volume sum is
`O(F)`. The independent reference counts canonically keyed unoriented edges
and their orientation balance, then uses the divergence-theorem face centroid
and area vector formula. Both references use exact integer rounding.

## Local distinction and sources

[`incremental_convex_hull_3d`](../i/incremental_convex_hull_3d/README.md)
constructs a convex hull and reports its volume. This package takes the
oriented surface mesh as input and sums its signed face contributions.
[`volume`](../v/volume/README.md) computes elementary formulas for cubes,
cuboids, prisms, and pyramids; it does not process meshes.

- Keenan Crane, [“Approximate Volume of a Nonplanar Quadrilateral Mesh”](https://www.cs.cmu.edu/~kmcrane/Projects/Other/QuadMeshVolume.pdf),
  section 1, states the piecewise-planar triangle-mesh formula as the sum of
  signed tetrahedral contributions `a·(b×c)/6`.
- Brian Mirtich, [“Fast and Accurate Computation of Polyhedral Mass
  Properties”](https://doi.org/10.1080/10867651.1996.10487458), *Journal of
  Graphics Tools* 1(2), 1996, develops polyhedral volume integrals from an
  oriented boundary representation. The independent face-flux reference here
  is the exact triangle specialization of the divergence theorem.
- KACTL's [geometry chapter index](https://github.com/kth-competitive-programming/kactl/blob/main/content/geometry/chapter.tex)
  supplied the discovery title `PolyhedronVolume.h`; its public
  [header description](https://github.com/kth-competitive-programming/kactl/blob/main/content/geometry/PolyhedronVolume.h)
  confirmed the supplied-mesh signed tetrahedron sum. Discovery metadata only;
  no code, examples, tests, or prose were copied.

[`workload.json`](workload.json) includes an outward and inward tetrahedron,
a triangulated cube, a translated mesh, bad edge orientation, an open mesh,
degenerate faces, malformed framing, and output-buffer errors. The two
references are `primary_oracle.py` and `independent_oracle.py`. The inventory
and workload reviewers are static-only and have not been run.

| Language | Source |
| --- | --- |
| C | [`c/p/polyhedron_volume.c`](../../../c/p/polyhedron_volume.c) |
| C3 | [`c3/p/polyhedron_volume.c3`](../../../c3/p/polyhedron_volume.c3) |
| C++ | [`cpp/p/polyhedron_volume.cpp`](../../../cpp/p/polyhedron_volume.cpp) |
| Elisa | [`elisa/p/polyhedron_volume.elisa`](../../../elisa/p/polyhedron_volume.elisa) |
| Mojo | [`mojo/p/polyhedron_volume.mojo`](../../../mojo/p/polyhedron_volume.mojo) |
| Nim | [`nim/p/polyhedron_volume.nim`](../../../nim/p/polyhedron_volume.nim) |
| Odin | [`odin/p/polyhedron_volume.odin`](../../../odin/p/polyhedron_volume.odin) |
| Rust | [`rust/p/polyhedron_volume.rs`](../../../rust/p/polyhedron_volume.rs) |
| V | [`v/p/polyhedron_volume.v`](../../../v/p/polyhedron_volume.v) |
| Zig | [`zig/p/polyhedron_volume.zig`](../../../zig/p/polyhedron_volume.zig) |
