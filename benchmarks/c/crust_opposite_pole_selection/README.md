# Crust opposite-pole selection

This package profiles the pole-selection subroutine of the three-dimensional
Crust algorithm. For each supplied non-convex-hull sample and its supplied
Voronoi-cell vertex candidates, it chooses the farthest vertex as the positive
pole, then chooses the farthest vertex whose displacement points into the
strictly opposite half-space as the negative pole.

## Bounded contract

- ABI: `i64_array_bytes_output`; symbol `crust_opposite_pole_selection`.
- Input: `[n,(sx,sy,sz,k,(vx,vy,vz)*k)*n]`. Each row starts with one sample
  coordinate, then a candidate count, then that row's Voronoi-cell vertex
  coordinates. Row-local candidate ordinals start at zero.
- `1<=n<=8`, `1<=k<=8` in every row, and each integer coordinate is in
  `[-16,16]`. Sample points are distinct. A row cannot repeat a candidate or
  use its own sample coordinate as a candidate. Maximum valid input is 225
  i64 words; the parser accepts up to 226 to classify a trailing word as
  malformed.
- For each row, the positive pole is the candidate maximizing squared
  Euclidean distance from the sample. Equal distances choose the lowest
  row-local ordinal. The negative pole is the farthest candidate whose
  displacement has a strictly negative dot product with the positive-pole
  displacement; equal distances again choose the lowest ordinal. Dot product
  zero is excluded. If no strictly opposite candidate exists, its ordinal is
  `-1`.
- Output is `[n,(positive_ordinal,negative_ordinal)*n]` as little-endian signed
  i64 words. The maximum output is 136 bytes; workspace is bounded to 1,024
  bytes. Invalid input returns `-1`; null or short output returns `-2` without
  writes. Input validation precedes output-capacity handling.

The source's geometric precondition is that each row is a complete finite
Voronoi cell of a sample not on the convex hull. Cell construction and that
precondition are supplied by the caller. The bounded ABI also defines the
no-opposite-candidate result (`-1`) so that this branch has a deterministic
test contract; it makes no reconstruction guarantee for such a row. Convex
hull samples, whose source normal is estimated from adjacent triangle
normals, are outside this profile.

This is distinct from [`crust_pole_triangle_filter`](../crust_pole_triangle_filter/README.md),
which accepts pole IDs and supplied augmented-Delaunay facets and only retains
sample-only triangles. This package selects poles; it does not build cells,
triangulations, or a reconstructed surface.

## Package files

- [`workload.json`](workload.json)
- [primary two-pass reference](primary_oracle.py)
- [independent brute-force scoring reference](independent_oracle.py)
- [`INVENTORY.md`](INVENTORY.md) and [`INVENTORY.json`](INVENTORY.json)
- [`check_inventory.py`](check_inventory.py) and [`verify_workload.py`](verify_workload.py)

## Sources and rights

The method is summarized in Amenta, *Encyclopedia of Algorithms*, Chapter
713, [DOI 10.1007/978-1-4939-2864-4_713](https://doi.org/10.1007/978-1-4939-2864-4_713).
The operational procedure is Amenta, Bern, and Kamvysselis, “A New
Voronoi-Based Surface Reconstruction Algorithm,” §4, Algorithm step 2(a,c),
pp. 4–5, SIGGRAPH '98, 415–421,
[DOI 10.1145/280814.280947](https://doi.org/10.1145/280814.280947). Step 2(a)
chooses the farthest Voronoi-cell vertex for a sample outside the convex hull;
step 2(c) chooses the farthest cell vertex with negative projection on the
first-pole direction. These references are used for mathematical method and
attribution only. No code, prose, figures, or fixtures are reused; see
[`RIGHTS.md`](RIGHTS.md).

| Language | Port |
|---|---|
| C | [`c/crust_opposite_pole_selection.c`](../../../c/crust_opposite_pole_selection.c) |
| C3 | [`c3/crust_opposite_pole_selection.c3`](../../../c3/crust_opposite_pole_selection.c3) |
| C++ | [`cpp/crust_opposite_pole_selection.cpp`](../../../cpp/crust_opposite_pole_selection.cpp) |
| Elisa | [`elisa/crust_opposite_pole_selection.elisa`](../../../elisa/crust_opposite_pole_selection.elisa) |
| Mojo | [`mojo/crust_opposite_pole_selection.mojo`](../../../mojo/crust_opposite_pole_selection.mojo) |
| Nim | [`nim/crust_opposite_pole_selection.nim`](../../../nim/crust_opposite_pole_selection.nim) |
| Odin | [`odin/crust_opposite_pole_selection.odin`](../../../odin/crust_opposite_pole_selection.odin) |
| Rust | [`rust/crust_opposite_pole_selection.rs`](../../../rust/crust_opposite_pole_selection.rs) |
| V | [`v/crust_opposite_pole_selection.v`](../../../v/crust_opposite_pole_selection.v) |
| Zig | [`zig/crust_opposite_pole_selection.zig`](../../../zig/crust_opposite_pole_selection.zig) |

No programs, tests, scripts, checkers, builds, compilers, profilers, or
benchmarks were run.

The shared byte-output runner and verifier plus README and CATALOG registration
are integrated. The Chapter 713 crosswalk marks this as a partial profile of
Crust; Voronoi-cell construction and full surface reconstruction remain outside
the package.
