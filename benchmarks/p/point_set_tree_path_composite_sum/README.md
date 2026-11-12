# Point Set Tree Path Composite Sum

Maintain values on the vertices of a fixed tree and affine maps on its edges.
After each update, return the sum of all path values when the query's supplied
vertex is the root. The same affine map is used when an edge is traversed in
either direction; reversing a path reverses composition order and does not
invert the map.

## Bounded ABI

The exported byte-output symbol is
`point_set_tree_path_composite_sum(const int64_t *input, size_t length,
uint8_t *output, size_t capacity) -> int64_t`.

Input is a signed 64-bit array:

```text
[N, Q, a_0..a_(N-1), (u,v,b,c)*(N-1), queries...]
```

`1 <= N <= 16`, `1 <= Q <= 32`, and the edges must form a connected tree.
Vertex values and affine addends are in `[0, 998244353)`; multipliers are in
`[1, 998244353)`. Queries are:

- `[0, w, x, r]`: set `a_w=x`, then report the aggregate rooted at `r`.
- `[1, e, y, z, r]`: set edge `e` to `y*t+z`, then report the aggregate rooted
  at `r`.

The output contains one little-endian signed 64-bit residue per query and
returns `8*Q` bytes written. Invalid input returns `-1`; null or undersized
output returns `-2` without writes. Maximum input length is 238 words, maximum
output is 256 bytes, and fixed workspace is 16 KiB.

The official task allows `N,Q <= 200000`; these local bounds retain both
update types, arbitrary roots, and noncommutative path order without claiming
the official scale.

## Dynamic top-tree summaries

The builder creates a balanced rake/compress cluster hierarchy. A vertex leaf
stores its value; an edge leaf stores the affine map in both directions. Each
cluster stores the number and sum of represented vertices when rooted at each
boundary, payload-presence flags for shared-boundary accounting, and forward
and reverse affine path maps. Rake and compress merges combine these summaries
while counting shared vertex payloads once.

A vertex or edge update changes one leaf and recalculates only its ancestor
clusters. To answer an arbitrary-root query, the implementation descends from
the full-tree cluster to that vertex while propagating the sibling clusters'
outside contributions through the stored directed path maps. Updates and
queries take `O(log^2 N)` worst-case summary work for the bounded balanced
hierarchy; construction uses `O(N^2 log N)` time and `O(N^2)` fixed storage.

The primary oracle uses the same incremental cluster summaries and top-down
outside contexts. The independent oracle walks every root-to-vertex path
directly after each update and sums the transformed vertex values.

## Provenance and language ports

The [official task](https://github.com/yosupo06/library-checker-problems/blob/master/tree/point_set_tree_path_composite_sum/task.md)
defines `P(x,y)` with the edge nearest `x` as the outermost map. The official
parameters are in
[`info.toml`](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/tree/point_set_tree_path_composite_sum/info.toml).
See [RIGHTS.md](RIGHTS.md) for attribution.

| Language | Port |
|---|---|
| C | [`c/p/point_set_tree_path_composite_sum.c`](../../../c/p/point_set_tree_path_composite_sum.c) |
| C3 | [`c3/p/point_set_tree_path_composite_sum.c3`](../../../c3/p/point_set_tree_path_composite_sum.c3) |
| C++ | [`cpp/p/point_set_tree_path_composite_sum.cpp`](../../../cpp/p/point_set_tree_path_composite_sum.cpp) |
| Elisa | [`elisa/p/point_set_tree_path_composite_sum.elisa`](../../../elisa/p/point_set_tree_path_composite_sum.elisa) |
| Mojo | [`mojo/p/point_set_tree_path_composite_sum.mojo`](../../../mojo/p/point_set_tree_path_composite_sum.mojo) |
| Nim | [`nim/p/point_set_tree_path_composite_sum.nim`](../../../nim/p/point_set_tree_path_composite_sum.nim) |
| Odin | [`odin/p/point_set_tree_path_composite_sum.odin`](../../../odin/p/point_set_tree_path_composite_sum.odin) |
| Rust | [`rust/p/point_set_tree_path_composite_sum.rs`](../../../rust/p/point_set_tree_path_composite_sum.rs) |
| V | [`v/p/point_set_tree_path_composite_sum.v`](../../../v/p/point_set_tree_path_composite_sum.v) |
| Zig | [`zig/p/point_set_tree_path_composite_sum.zig`](../../../zig/p/point_set_tree_path_composite_sum.zig) |

The bounded workload and package-local static checker are
[`workload.json`](workload.json) and [`verify_workload.py`](verify_workload.py).
