# Dynamic tree subtree add and subtree sum

This package maintains a vertex-weighted tree under edge replacement. Each
update adds a nonnegative amount to one entire side of an adjacent edge, and
each query returns the sum on that side. The side is defined by `(v,p)`: remove
edge `(v,p)`, then select the component containing `v`.

This is a distinct dynamic-tree workload from
[`dynamic_tree_vertex_add_subtree_sum`](../dynamic_tree_vertex_add_subtree_sum/README.md),
which changes one vertex at a time. Supporting a whole-side update requires a
lazy range tag over the virtual Euler-tour interval, in addition to dynamic
link and cut operations. The existing [`link_cut_tree`](../../l/link_cut_tree/README.md)
supports path aggregates and does not maintain this Euler-tour interval.

## Input and ABI

The exported symbol is `dynamic_tree_subtree_add_subtree_sum` with ABI
`i64_array_bytes_output`:

```text
[N, Q, value[N], initial_edges[2*(N-1)], events[5*Q]]
```

The bounded profile has `1 <= N <= 16`, `0 <= Q <= 32`, initial values and
update deltas in `0..=1000`, and exactly `3*N + 5*Q` signed 64-bit words.
Vertices are zero-based. Event records are:

- `[0,u,v,w,x]`: replace present edge `(u,v)` with `(w,x)`; the endpoints must
  be separated by removing `(u,v)`.
- `[1,v,p,delta,0]`: add `delta` to every vertex in the component on `v`'s
  side of adjacent edge `(v,p)`.
- `[2,v,p,0,0]`: return the sum of values on the same side.

Initial edges must form a tree, replacements must preserve a tree, and update
or query parents must be adjacent. Values remain nonnegative and at most
`1000 + 32*1000 = 33000`; every valid sum fits signed 64-bit.

Each query emits one signed 64-bit little-endian result, up to 256 output bytes.
Success returns the number of bytes written. Invalid input or topology returns
`-1`; a null or short output buffer for a nonempty result returns `-2`. Calls
stage answers before writing, so error results leave output untouched. Zero
queries accept a null output. Workspace is bounded to 16 KiB.

## Algorithm

Each tree is a cyclic Euler tour stored as an implicit randomized treap. Every
vertex has one marker token carrying its value; every edge has two directed
tokens. Removing the two tokens of an edge splits the cyclic tour into the two
component tours. For `(v,p)`, the interval after directed token `p->v` and
before `v->p` contains exactly the vertex markers on `v`'s side. Treap range
sum and lazy range add act only on marker tokens, while edge tokens contribute
zero. Linking two components splices their tours at the endpoint markers and
inserts the two new directed edge tokens.

Link, cut, side update, and side sum take expected `O(log(N+Q))` time per
event, with `O(N+Q)` treap storage. The ABI preflight checks edge replacement
connectivity with bounded adjacency walks, so a complete call takes
`O(N^2 + NQ + (N+Q) log(N+Q))` time. The primary oracle uses direct edge-set
traversals; the independent verifier rebuilds an adjacency matrix and walks
each selected component with a queue.

## Sources and ports

The operations follow Library Checker's
[`Dynamic Tree Subtree Add Subtree Sum`](https://judge.yosupo.jp/problem/dynamic_tree_subtree_add_subtree_sum)
task and its [proposal](https://github.com/yosupo06/library-checker-problems/issues/521).
The upstream repository is Apache-2.0. These ports are clean-room implementations
of the operation semantics and Euler-tour-tree method; see [RIGHTS.md](RIGHTS.md).

| Language | Port |
|---|---|
| C | [`c/d/dynamic_tree_subtree_add_subtree_sum.c`](../../../c/d/dynamic_tree_subtree_add_subtree_sum.c) |
| C3 | [`c3/d/dynamic_tree_subtree_add_subtree_sum.c3`](../../../c3/d/dynamic_tree_subtree_add_subtree_sum.c3) |
| C++ | [`cpp/d/dynamic_tree_subtree_add_subtree_sum.cpp`](../../../cpp/d/dynamic_tree_subtree_add_subtree_sum.cpp) |
| Elisa | [`elisa/d/dynamic_tree_subtree_add_subtree_sum.elisa`](../../../elisa/d/dynamic_tree_subtree_add_subtree_sum.elisa) |
| Mojo | [`mojo/d/dynamic_tree_subtree_add_subtree_sum.mojo`](../../../mojo/d/dynamic_tree_subtree_add_subtree_sum.mojo) |
| Nim | [`nim/d/dynamic_tree_subtree_add_subtree_sum.nim`](../../../nim/d/dynamic_tree_subtree_add_subtree_sum.nim) |
| Odin | [`odin/d/dynamic_tree_subtree_add_subtree_sum.odin`](../../../odin/d/dynamic_tree_subtree_add_subtree_sum.odin) |
| Rust | [`rust/d/dynamic_tree_subtree_add_subtree_sum.rs`](../../../rust/d/dynamic_tree_subtree_add_subtree_sum.rs) |
| V | [`v/d/dynamic_tree_subtree_add_subtree_sum.v`](../../../v/d/dynamic_tree_subtree_add_subtree_sum.v) |
| Zig | [`zig/d/dynamic_tree_subtree_add_subtree_sum.zig`](../../../zig/d/dynamic_tree_subtree_add_subtree_sum.zig) |

Oracles: [primary direct traversal](../../dynamic_tree_subtree_add_subtree_sum_oracle.py),
[independent verifier](../../dynamic_tree_subtree_add_subtree_sum_verifier_oracle.py).
