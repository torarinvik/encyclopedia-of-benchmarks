# Vertex add range contour sum on tree

This bounded profile maintains signed values on an undirected tree. A point
update adds to one vertex; a contour query sums values at all vertices whose
tree distance from a selected vertex lies in a half-open interval. The ports
use centroid decomposition. Each vertex records its centroid ancestors,
distance to each ancestor, and the child branch containing it. Each centroid
has a Fenwick row for all vertices in its component; each child branch has a
second row. Updates add along the centroid-ancestor chain. Queries sum a
shifted distance interval from the total row and subtract the matching branch
row, so each vertex is counted at its first separating centroid.

The decomposition takes `O(N log N)` work. Initial bucket loading, point
updates, and contour queries take `O(log^2 N)` each. The local fixed-size rows
reserve `O(N^2)` storage at the declared `N <= 64` cap; only `O(N log N)` row
positions are logically used.

## Contract

The signed 64-bit input array is encoded as
`[N,Q,values[N],edges[2*(N-1)],operations...]`. Each undirected edge is a
`(u,v)` pair in arbitrary order. Operation `0` is `[0,p,x]` and adds signed
delta `x` to vertex `p`. Operation `1` is `[1,p,l,r]` and returns the sum of
current values at vertices whose distance from `p` is in `[l,r)`. The input
length is variable because these two operation records have different sizes.

The local bounds are `1 <= N <= 64`, `0 <= Q <= 128`, initial values and
updates in `[-1,000,000,1,000,000]`, and `0 <= l < r <= N`. The maximum valid
input has 704 signed 64-bit words; one extra word is accepted by the ABI parser
only to reject trailing input cleanly. The maximum output is 1,024 bytes. A
successful call writes one signed 64-bit little-endian answer per query and
returns the byte count. Invalid input returns `-1`. A null or undersized output
buffer for a nonempty result returns `-2`, without writing output. The
`workspace.bytes` field records output-buffer capacity; the tree and centroid
tables are separate bounded storage.

The official task permits `N <= 100,000`, `Q <= 200,000`, and initial/update
values of magnitude at most `10^9`. The smaller local caps preserve the
centroid-decomposition and Fenwick operations across all ten language ports.

## Distinctness

[`vertex_add_subtree_sum`](../vertex_add_subtree_sum/README.md) queries a fixed
rooted subtree through Euler intervals; it does not select vertices by
distance from an arbitrary center. [`heavy_light_path_sum`](../../h/heavy_light_path_sum/README.md)
answers path aggregates and has point-set updates. The generic
[`centroid_decomposition`](../../c/centroid_decomposition/README.md) package
constructs the centroid-parent tree but does not maintain weighted contour
sums. The inverse `vertex_get_range_contour_add_on_tree` task is a close dual
and is not counted here as a separate algorithm.

Official contract: [Library Checker — Vertex Add Range Contour Sum on Tree](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/tree/vertex_add_range_contour_sum_on_tree/task.md),
[limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/tree/vertex_add_range_contour_sum_on_tree/info.toml),
and [reference solution](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/tree/vertex_add_range_contour_sum_on_tree/sol/correct_invertible.cpp).
The implementations here are clean-room ports of the bounded centroid-bucket
profile and do not copy upstream source code.

## Workload and independent oracles

[`workload.json`](workload.json) includes singleton, signed-value, branching,
path, and star trees; updates and distance queries; malformed tree and query
frames; null output; and insufficient output capacity. The primary
[`benchmarks/vertex_add_range_contour_sum_on_tree_oracle.py`](../../vertex_add_range_contour_sum_on_tree_oracle.py)
performs a fresh BFS for each query. The independent
[`benchmarks/vertex_add_range_contour_sum_on_tree_checker.py`](../../vertex_add_range_contour_sum_on_tree_checker.py)
precomputes all-pairs BFS distances once and scans vertices for each query.
See [`RIGHTS.md`](RIGHTS.md) for attribution and provenance.

## Implementations

| Language | Source |
|---|---|
| C | [`c/v/vertex_add_range_contour_sum_on_tree.c`](../../../c/v/vertex_add_range_contour_sum_on_tree.c) |
| C3 | [`c3/v/vertex_add_range_contour_sum_on_tree.c3`](../../../c3/v/vertex_add_range_contour_sum_on_tree.c3) |
| C++ | [`cpp/v/vertex_add_range_contour_sum_on_tree.cpp`](../../../cpp/v/vertex_add_range_contour_sum_on_tree.cpp) |
| Elisa | [`elisa/v/vertex_add_range_contour_sum_on_tree.elisa`](../../../elisa/v/vertex_add_range_contour_sum_on_tree.elisa) |
| Mojo | [`mojo/v/vertex_add_range_contour_sum_on_tree.mojo`](../../../mojo/v/vertex_add_range_contour_sum_on_tree.mojo) |
| Nim | [`nim/v/vertex_add_range_contour_sum_on_tree.nim`](../../../nim/v/vertex_add_range_contour_sum_on_tree.nim) |
| Odin | [`odin/v/vertex_add_range_contour_sum_on_tree.odin`](../../../odin/v/vertex_add_range_contour_sum_on_tree.odin) |
| Rust | [`rust/v/vertex_add_range_contour_sum_on_tree.rs`](../../../rust/v/vertex_add_range_contour_sum_on_tree.rs) |
| V | [`v/v/vertex_add_range_contour_sum_on_tree.v`](../../../v/v/vertex_add_range_contour_sum_on_tree.v) |
| Zig | [`zig/v/vertex_add_range_contour_sum_on_tree.zig`](../../../zig/v/vertex_add_range_contour_sum_on_tree.zig) |
