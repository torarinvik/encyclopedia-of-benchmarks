# Dynamic tree vertex add and subtree sum

This package maintains an undirected tree while edges are replaced, adds weight
to individual vertices, and reports the sum on one side of a selected edge.
For a query `(v, p)`, `p` is an adjacent vertex treated as the parent; the
answer includes `v` and every vertex reachable from `v` without crossing
`(v, p)`. This dynamic operation is distinct from the static
[`vertex_add_subtree_sum`](../../v/vertex_add_subtree_sum/README.md), which fixes
one root and uses Euler intervals, and from [`link_cut_tree`](../../l/link_cut_tree/README.md),
which maintains path aggregates but not virtual-subtree totals.

## Input and ABI

The exported C ABI symbol is
`dynamic_tree_vertex_add_subtree_sum(const int64_t *input, size_t length,
uint8_t *output, size_t capacity)`. It uses `i64_array_bytes_output`.

Input is the signed 64-bit array:

```text
[N, Q, value[N], initial_edges[2*(N-1)], events[5*Q]]
```

The bounds are `1 <= N <= 32`, `0 <= Q <= 64`, and exactly `3*N + 5*Q`
input words. Initial values and update deltas are in `0..=1,000`; values stay
nonnegative and at most `1,000 + 64*1,000`.

Each event is a fixed five-word record:

- `[0, u, v, w, x]`: replace edge `(u,v)` with `(w,x)`.
- `[1, p, delta, 0, 0]`: add `delta` to vertex `p`.
- `[2, v, p, 0, 0]`: query the `v` side of the edge `(v,p)`.

Vertices are zero-based. Initial edges must form a tree, every replacement
must remove a present edge and insert an edge between the resulting components,
and a query's parent must be adjacent to its vertex. These topology conditions
are the problem preconditions. Ports reject malformed lengths, out-of-range
values or vertices, unknown event kinds, and nonzero reserved fields.

Each query emits one signed 64-bit little-endian sum in event order. The output
buffer is at most `8*Q` bytes (512 bytes). A successful call returns the number
of bytes written; malformed input or topology returns `-1`; a null or
undersized output buffer returns `-2` when at least one query needs output.
Validation and processing finish before output is written, so error returns
leave the output untouched. A zero-query trace returns zero even with a null
output pointer.

## Algorithm

The ports use a splay-based link-cut tree. Each auxiliary node stores its
vertex value, the sum of its preferred-path splay subtree, and the sum of its
virtual child trees. During `access`, the old preferred right branch is added
to the virtual total and the newly preferred branch is removed from it. To
answer a side-of-edge query, the port makes `p` the represented root and
accesses `v`; `value[v] + virtual_sum[v]` is the component on `v`'s side.
Edge replacement uses a link-cut cut followed by a link, and point addition
accesses and updates the selected node.

Construction and each event take amortized `O(log N)` time; the workload takes
`O((N+Q) log N)` amortized time and `O(N+Q)` bounded storage including staged
answers. Elisa keeps the tree state in fixed arrays and safe views; references
are used only at the exported ABI.

## Source and rights

The operation follows the official [Library Checker task statement](https://github.com/yosupo06/library-checker-problems/blob/master/tree/dynamic_tree_vertex_add_subtree_sum/task.md)
and its [limits](https://github.com/yosupo06/library-checker-problems/blob/master/tree/dynamic_tree_vertex_add_subtree_sum/info.toml).
The upstream problem repository is Apache-2.0. These ports use the operation
semantics and a clean-room description of the virtual-subtree link-cut method;
they do not copy upstream solution code. See [RIGHTS.md](RIGHTS.md).

The primary oracle recomputes each answer by traversing the edge set while
excluding the queried parent edge. The independent verifier rebuilds an
adjacency matrix and performs a separate iterative component traversal.

## Workload and ports

[`workload.json`](workload.json) includes edge replacement, updates, queries on
both sides of an edge, a one-vertex zero-output call, invalid framing and
reserved-field cases, and output-capacity failures. The byte-output verifier
also prepares maximum-size query and mixed-operation traces without adding
those generated traces to the fixed workload fixtures.

| Language | Port |
|---|---|
| C | [`c/d/dynamic_tree_vertex_add_subtree_sum.c`](../../../c/d/dynamic_tree_vertex_add_subtree_sum.c) |
| C3 | [`c3/d/dynamic_tree_vertex_add_subtree_sum.c3`](../../../c3/d/dynamic_tree_vertex_add_subtree_sum.c3) |
| C++ | [`cpp/d/dynamic_tree_vertex_add_subtree_sum.cpp`](../../../cpp/d/dynamic_tree_vertex_add_subtree_sum.cpp) |
| Elisa | [`elisa/d/dynamic_tree_vertex_add_subtree_sum.elisa`](../../../elisa/d/dynamic_tree_vertex_add_subtree_sum.elisa) |
| Mojo | [`mojo/d/dynamic_tree_vertex_add_subtree_sum.mojo`](../../../mojo/d/dynamic_tree_vertex_add_subtree_sum.mojo) |
| Nim | [`nim/d/dynamic_tree_vertex_add_subtree_sum.nim`](../../../nim/d/dynamic_tree_vertex_add_subtree_sum.nim) |
| Odin | [`odin/d/dynamic_tree_vertex_add_subtree_sum.odin`](../../../odin/d/dynamic_tree_vertex_add_subtree_sum.odin) |
| Rust | [`rust/d/dynamic_tree_vertex_add_subtree_sum.rs`](../../../rust/d/dynamic_tree_vertex_add_subtree_sum.rs) |
| V | [`v/d/dynamic_tree_vertex_add_subtree_sum.v`](../../../v/d/dynamic_tree_vertex_add_subtree_sum.v) |
| Zig | [`zig/d/dynamic_tree_vertex_add_subtree_sum.zig`](../../../zig/d/dynamic_tree_vertex_add_subtree_sum.zig) |

Oracle modules: [`dynamic_tree_vertex_add_subtree_sum_oracle.py`](../../dynamic_tree_vertex_add_subtree_sum_oracle.py) and [`dynamic_tree_vertex_add_subtree_sum_verifier_oracle.py`](../../dynamic_tree_vertex_add_subtree_sum_verifier_oracle.py).
