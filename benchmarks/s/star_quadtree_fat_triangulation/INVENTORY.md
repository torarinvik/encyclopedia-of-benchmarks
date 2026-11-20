# Source inventory

| Language | Source |
|---|---|
| C | `c/s/star_quadtree_fat_triangulation.c` |
| C3 | `c3/s/star_quadtree_fat_triangulation.c3` |
| C++ | `cpp/s/star_quadtree_fat_triangulation.cpp` |
| Elisa | `elisa/s/star_quadtree_fat_triangulation.elisa` |
| Mojo | `mojo/s/star_quadtree_fat_triangulation.mojo` |
| Nim | `nim/s/star_quadtree_fat_triangulation.nim` |
| Odin | `odin/s/star_quadtree_fat_triangulation.odin` |
| Rust | `rust/s/star_quadtree_fat_triangulation.rs` |
| V | `v/s/star_quadtree_fat_triangulation.v` |
| Zig | `zig/s/star_quadtree_fat_triangulation.zig` |

The two source references are `primary_oracle.py` (active top-down stopping
recursion) and `independent_oracle.py` (all-cell scan with rational clipping).
The pinned bounded profile has at most five vertices, four triangles, depth 2,
16 leaves, 64 cell-triangle pairs, a 1,032-byte output, and 8,192 bytes of
declared workspace. `check_inventory.py` checks the language file set and
metadata statically; it is provided for suite integration and has not been
run.
