# Tree random-walk edge hitting costs

For every input edge, this benchmark returns the expected weighted traversal
cost from its first endpoint until the walk first reaches the second endpoint,
then the reverse-direction expectation. The walk chooses each adjacent vertex
uniformly; crossing an edge adds that edge's positive integer weight to the
cost. Records and endpoint orientation are preserved in the output.

Input is `[n,root,(u,v,w)*(n-1)]`. The tree has 1 through 16 vertices, the
root is zero-based, and every edge weight is in 1..9. The `n-1` records must
form a simple undirected tree; records may appear in any order and either
orientation. Output contains two little-endian signed 64-bit integers per
input edge: the expected cost from `u` to `v`, followed by the expected cost
from `v` to `u`. Invalid or null input returns `-1`; null or short output
returns `-2` without writes. The exact valid input length is `2+3(n-1)`, at
most 47 words; one trailing word is parseable but invalid. Output uses at most
240 bytes. A conservative 16384-byte workspace cap includes all fixed graph,
traversal, recurrence, and output state.

Rooting the tree once, the postorder recurrence sets
`down[u] = sum(weight(u,t) for incident edges) + sum(down[child])` for each
vertex. At the root, `down[root]` is only an auxiliary aggregate for this
recurrence; it does not represent an expectation toward a nonexistent parent.
The preorder recurrence sets
`up[root]=0` and `up[child]=up[parent]+down[parent]-down[child]`. For a
parent-child edge, `down[child]` is the child-to-parent expectation and
`up[child]` is the parent-to-child expectation. This uses `O(n)` time and
`O(n)` storage with adjacency lists.

The primary reference applies those two recurrences. The independent
reference builds and solves the first-step equations for each target using
exact `Fraction` Gaussian elimination, then asserts each expected value is an
integer. The workload covers both orientations, weighted branches, a chain,
the one-vertex empty-output case, malformed trees and roots, and output
capacity errors.

The algorithm idea is described by [OI Wiki — Random Walk on a Tree](https://oi-wiki.org/graph/tree-random-walk/).
The page is used as a method reference only. The contract, fixtures, references,
and clean-room language ports are independently authored.

## Implementations

| Language | Source |
|---|---|
| C | [`c/t/tree_random_walk_edge_hitting_cost.c`](../../../c/t/tree_random_walk_edge_hitting_cost.c) |
| C3 | [`c3/t/tree_random_walk_edge_hitting_cost.c3`](../../../c3/t/tree_random_walk_edge_hitting_cost.c3) |
| C++ | [`cpp/t/tree_random_walk_edge_hitting_cost.cpp`](../../../cpp/t/tree_random_walk_edge_hitting_cost.cpp) |
| Elisa | [`elisa/t/tree_random_walk_edge_hitting_cost.elisa`](../../../elisa/t/tree_random_walk_edge_hitting_cost.elisa) |
| Mojo | [`mojo/t/tree_random_walk_edge_hitting_cost.mojo`](../../../mojo/t/tree_random_walk_edge_hitting_cost.mojo) |
| Nim | [`nim/t/tree_random_walk_edge_hitting_cost.nim`](../../../nim/t/tree_random_walk_edge_hitting_cost.nim) |
| Odin | [`odin/t/tree_random_walk_edge_hitting_cost.odin`](../../../odin/t/tree_random_walk_edge_hitting_cost.odin) |
| Rust | [`rust/t/tree_random_walk_edge_hitting_cost.rs`](../../../rust/t/tree_random_walk_edge_hitting_cost.rs) |
| V | [`v/t/tree_random_walk_edge_hitting_cost.v`](../../../v/t/tree_random_walk_edge_hitting_cost.v) |
| Zig | [`zig/t/tree_random_walk_edge_hitting_cost.zig`](../../../zig/t/tree_random_walk_edge_hitting_cost.zig) |

[`verify_workload.py`](verify_workload.py) checks package metadata, workload
frames against both references, and the ten source paths. No drafts have been
compiled or executed.
