# Star quadtree for fat triangulations

This package builds the Star-quadtree subdivision for a small, explicit set of
fat triangulations. A cell stops when its intersecting triangulation edges all
share a vertex; empty cells stop as well. The primary reference applies the
paper's direct top-down construction and emits cell-triangle intersections in
Z order.

## Bounded contract

The `i64_array_bytes_output` input is
`[vertex_count, triangle_count, x0,y0,..., (a,b,c) per triangle]`. It accepts
the canonical square with vertices `(0,0),(8,0),(8,8),(0,8)` and either of its
two diagonal triangulations, plus the four-triangle fan through center `(4,4)`.
The accepted frames and triangle order are listed in
[`workload.json`](workload.json). These triangles all have minimum angle 45°.

The algorithm splits an active cell if its intersecting edges do not share a
common endpoint. Cell-edge contact is closed. Child traversal order is
northwest, northeast, southwest, southeast. The bounded profile has maximum
depth 2; an unsatisfied stopping rule at that depth is invalid. For these
three fixed geometries, nonincident edge pairs are at least 4 units apart,
while a depth-2 cell has diagonal `2√2`, so the cap includes the complete
subdivision.

The output is little-endian signed i64 words
`[pair_count, z_key, triangle_id, ...]`. Each pair represents one leaf-cell /
triangle intersection, with `z_key` the fixed-depth-2 Morton start key. Z
coordinates use the paper's top-left origin; bits are interleaved row first,
then x, which gives the same NW, NE, SW, SE order. Pairs are sorted by key and
then by the input triangle ID. The maximum frame is 24 words (25 parseable
words to detect a trailing-word probe), the output bound is 1,032 bytes, and
the declared workspace is 8,192 bytes. Invalid input returns `-1`; null or
short output returns `-2`; errors write no bytes.

This is a distinct profile from [`pmr_edge_quadtree`](../../p/pmr_edge_quadtree/README.md):
PMR indexes segments and splits by an edge-count threshold, while Star
quadtrees split based on whether the intersecting triangulation edges share a
common vertex. It is also distinct from [`morton_sort`](../../m/morton_sort/README.md),
which only orders points by Morton code, and [`quad_tree`](../../q/quad_tree/README.md),
which indexes points for range queries.

The book chapter defines the Star stopping rule and Z-order representation.
The primary paper also gives a per-vertex-star method that constructs final
cells locally, sorts triangle-key pairs, and removes duplicates (§2.3). This
small profile benchmarks the same subdivision with the paper's explicitly
described direct top-down construction; it does not claim the I/O bound of the
per-star construction, build the B-tree, or cover arbitrary triangulation
validation. The independent reference scans all canonical cells through depth
2 and tests each candidate against its parent, using rational segment-box
clipping instead of recursive construction.

The source is Mark de Berg, Herman Haverkort, Shripad Thite, and Laura Toma,
“Star-quadtrees and guard-quadtrees: I/O-efficient indexes for fat
triangulations and low-density planar subdivisions,” *Computational Geometry*
43(5), 493–513 (2010), [doi:10.1016/j.comgeo.2009.11.001](https://doi.org/10.1016/j.comgeo.2009.11.001),
§§2.1–2.3, and Haverkort and Toma, “Quadtrees and Morton Indexing,” Chapter
585, *Encyclopedia of Algorithms*,
[doi:10.1007/978-1-4939-2864-4_585](https://doi.org/10.1007/978-1-4939-2864-4_585).
Only the mathematical procedures and definitions were consulted; all source
code, ABI choices, bounds, serialization, fixtures, and language ports are
clean-room work. See [RIGHTS.md](RIGHTS.md) and
[INVENTORY.md](INVENTORY.md).

## Language ports

- [C](../../../c/s/star_quadtree_fat_triangulation.c)
- [C3](../../../c3/s/star_quadtree_fat_triangulation.c3)
- [C++](../../../cpp/s/star_quadtree_fat_triangulation.cpp)
- [Elisa](../../../elisa/s/star_quadtree_fat_triangulation.elisa)
- [Mojo](../../../mojo/s/star_quadtree_fat_triangulation.mojo)
- [Nim](../../../nim/s/star_quadtree_fat_triangulation.nim)
- [Odin](../../../odin/s/star_quadtree_fat_triangulation.odin)
- [Rust](../../../rust/s/star_quadtree_fat_triangulation.rs)
- [V](../../../v/s/star_quadtree_fat_triangulation.v)
- [Zig](../../../zig/s/star_quadtree_fat_triangulation.zig)
