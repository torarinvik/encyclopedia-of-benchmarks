# Vertex add subtree sum

This profile maintains values on a static rooted tree. A point update adds to
one vertex; a query returns the sum over that vertex's rooted subtree. The
implementation numbers vertices in Euler preorder, so every subtree occupies
one half-open interval, then uses a Fenwick tree for point additions and range
sums. Euler preprocessing takes `O(N)` time; building the Fenwick tree by
point additions takes `O(N log N)` time. Storage is `O(N)`, and each update
and query takes `O(log N)` time.

## Contract

Input is a signed 64-bit array
`[N,Q,values[N],parents[N-1],(operation,vertex,operand)[Q]]`. Vertex `0` is the
root. For each vertex `v > 0`, `parents[v-1]` is in `[0,v)`, matching the
official parent ordering. Operation `0` adds `operand` to `vertex`; operation
`1` queries that vertex's subtree and requires `operand=0`. Initial values and
update deltas are in `[0,1,000,000]`. The local bounds are `1 <= N <= 128` and
`0 <= Q <= 256`, with exact input length `2*N+1+3*Q`.

Successful calls write one signed 64-bit little-endian answer per query and
return the byte count. Invalid input returns `-1`. When answers need to be
written, null or undersized output returns `-2` without writing. The maximum
output buffer is 2,048 bytes; tree, Euler-order, and Fenwick arrays are
separate bounded storage.

The official task allows `N,Q <= 500,000` and values/deltas through `10^9`.
The local caps keep all ten ports and the direct oracle small while retaining
the Euler-tour/Fenwick operation. The independent oracle enumerates each
queried subtree directly from child lists rather than using Euler intervals or
a Fenwick tree.

This is distinct from [`fenwick_tree`](../../f/fenwick_tree/README.md), whose
input is already a flat array and has no tree preprocessing or subtree
semantics, and from [`heavy_light_path_sum`](../../h/heavy_light_path_sum/README.md),
which uses HLD and a segment tree for path queries with point-set updates.

Official contract: [Library Checker — Vertex Add Subtree Sum](https://github.com/yosupo06/library-checker-problems/blob/master/tree/vertex_add_subtree_sum/task.md)
and its [limits](https://github.com/yosupo06/library-checker-problems/blob/master/tree/vertex_add_subtree_sum/info.toml).

## Workload and oracle

[`workload.json`](workload.json) covers a single vertex, branching subtrees,
updates, root and leaf queries, malformed parent data, malformed operations,
and output-capacity failures. The suite uses
[`benchmarks/vertex_add_subtree_sum_oracle.py`](../../vertex_add_subtree_sum_oracle.py),
which computes each answer with a direct traversal of the queried subtree.

## Implementations

| Language | Source |
|---|---|
| C | [`c/v/vertex_add_subtree_sum.c`](../../../c/v/vertex_add_subtree_sum.c) |
| C3 | [`c3/v/vertex_add_subtree_sum.c3`](../../../c3/v/vertex_add_subtree_sum.c3) |
| C++ | [`cpp/v/vertex_add_subtree_sum.cpp`](../../../cpp/v/vertex_add_subtree_sum.cpp) |
| Elisa | [`elisa/v/vertex_add_subtree_sum.elisa`](../../../elisa/v/vertex_add_subtree_sum.elisa) |
| Mojo | [`mojo/v/vertex_add_subtree_sum.mojo`](../../../mojo/v/vertex_add_subtree_sum.mojo) |
| Nim | [`nim/v/vertex_add_subtree_sum.nim`](../../../nim/v/vertex_add_subtree_sum.nim) |
| Odin | [`odin/v/vertex_add_subtree_sum.odin`](../../../odin/v/vertex_add_subtree_sum.odin) |
| Rust | [`rust/v/vertex_add_subtree_sum.rs`](../../../rust/v/vertex_add_subtree_sum.rs) |
| V | [`v/v/vertex_add_subtree_sum.v`](../../../v/v/vertex_add_subtree_sum.v) |
| Zig | [`zig/v/vertex_add_subtree_sum.zig`](../../../zig/v/vertex_add_subtree_sum.zig) |
