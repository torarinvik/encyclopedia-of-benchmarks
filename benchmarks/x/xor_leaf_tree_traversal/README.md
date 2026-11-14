# XOR leaf-peeling tree traversal

This benchmark roots an undirected tree by repeatedly removing non-root
leaves. Each vertex tracks its remaining degree and the XOR of its incident
edge IDs; once a non-root vertex has one remaining edge, that XOR identifies
its parent edge. Removing it updates both the degree and edge XOR of its
neighbor. It produces a child-before-parent order and a parent-edge array.

This differs from the existing [depth-first traversal](../../d/depth_first_search/README.md),
which explores from a root, and [Prüfer encoding](../../p/prufer_code/README.md),
which removes leaves in a priority order to produce a code. The XOR-based
method uses a different state representation and produces a rooted traversal.

## Bounded contract

Use `i64_array_bytes_output`, symbol `xor_leaf_tree_traversal`, with input
`[n,root,(u,v)...]`: `1 <= n <= 64`, a root in `[0,n)`, and exactly `n-1`
simple undirected edges in input order. Reject invalid endpoints, duplicate
edges, cycles, disconnected graphs, and malformed framing with `-1`. Edge IDs
are their zero-based input positions. Process candidate vertices in ascending
ID order, following a newly exposed leaf immediately until reaching the root
or a non-leaf. Emit `[parent_edge_0,...,parent_edge_(n-1),order_0,...,order_(n-1)]`
as little-endian signed 64-bit integers; the root's parent edge is `-1`, and
the root is last in the order. Return `16*n` bytes on success; null or short
output returns `-2` without writes. Maximum output is 1024 bytes.

The leaf-peeling algorithm uses O(n) time and O(n) storage for a valid tree.
The drafts validate with union by rank and path compression, adding
O(n α(n)) amortized time. The reference roots the tree with breadth-first
search and tracks remaining children independently. The
[primary reference](primary_oracle.py) separately models the XOR state.

## Provenance and status

The idea was identified from [CP-Algorithms' ascending tree traversal](https://github.com/cp-algorithms/cp-algorithms-aux/blob/7a28ec7ac05eabf2ceeed1778e2b2110a1e1c022/cp-algo/tree/ascending_dfs.hpp),
pinned at commit `7a28ec7ac05eabf2ceeed1778e2b2110a1e1c022` (file blob
`03694fe919ee845066dda0e365413b68b63ce24d`).
The upstream repository identifies its license as [CC BY-SA 4.0](https://github.com/cp-algorithms/cp-algorithms-aux).
The contract above is independently specified; no source code, examples, or
prose were copied. See [RIGHTS.md](RIGHTS.md). Uncompiled drafts exist for [C](../../../c/x/xor_leaf_tree_traversal.c),
[C3](../../../c3/x/xor_leaf_tree_traversal.c3),
[C++](../../../cpp/x/xor_leaf_tree_traversal.cpp),
[Elisa](../../../elisa/x/xor_leaf_tree_traversal.elisa),
[Mojo](../../../mojo/x/xor_leaf_tree_traversal.mojo),
[Nim](../../../nim/x/xor_leaf_tree_traversal.nim),
[Odin](../../../odin/x/xor_leaf_tree_traversal.odin),
[Rust](../../../rust/x/xor_leaf_tree_traversal.rs),
[V](../../../v/x/xor_leaf_tree_traversal.v), and
[Zig](../../../zig/x/xor_leaf_tree_traversal.zig), alongside an
[independent reference](oracle.py). The [workload](workload.json) and
byte-output suite registration are present as drafts. None has been run or
compiled. The Elisa draft uses ABI references and local fixed arrays.
The verifier source also constructs chains, stars, and seeded random trees
with varied roots and edge orderings, checks buffer failures, and includes
cyclic and malformed graphs; those checks remain unrun.
