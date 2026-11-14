# Incremental minimum spanning forest

This package is a work in progress. It will measure insertion-only maintenance
of a minimum spanning forest: each new edge either joins two components,
replaces the heaviest edge on the existing forest path, or is itself rejected.
The output records the displaced insertion index, using `-1` when no edge is
displaced. This stateful update profile is distinct from the repository's
static minimum-spanning-tree, spanning-forest, and KKT sampled-filter kernels.

The bounded input is `[n,m,(u,v,weight)*m]`, with 1–16 vertices,
1–32 insertions, endpoints in `[0,n)`, and distinct positive weights in
`[1,1000000]`. Parallel edges and self-loops are allowed. Each answer will be
an i64: `-1` for a component-joining edge, the new edge's own index for a
rejected edge (including a self-loop), or the replaced forest edge's index.
All endpoints and weights will be validated before output is written.

The primary model is [`primary_oracle.py`](primary_oracle.py); the independent
[`independent_oracle.py`](independent_oracle.py) recomputes each prefix forest
using Kruskal's algorithm. [`workload.json`](workload.json) includes joins,
replacement, rejection, parallel edges, self-loops, and error cases. The C and
Rust drafts scan prior edges while searching each forest path, taking
O(nm²) time and O(n+m) space. This is a bounded profile, not a claim of the
polylogarithmic update complexity of dynamic-tree implementations.

The idea and output convention come from the Library Checker
[`Incremental Minimum Spanning Forest`](https://github.com/yosupo06/library-checker-problems/blob/73876f1cbcf082d2b22722924b924d3d65a2f00e/graph/incremental_minimum_spanning_forest/task.md)
listing. Its repository root carries [Apache-2.0](https://github.com/yosupo06/library-checker-problems/blob/master/LICENSE);
this package independently expresses the algorithm and does not copy its
problem text, code, or test data. The catalog revision is pinned to
`73876f1cbcf082d2b22722924b924d3d65a2f00e`.

Draft ports: [C](../../../c/i/incremental_minimum_spanning_forest.c),
[C3](../../../c3/i/incremental_minimum_spanning_forest.c3),
[C++](../../../cpp/i/incremental_minimum_spanning_forest.cpp),
[Elisa](../../../elisa/i/incremental_minimum_spanning_forest.elisa),
[Mojo](../../../mojo/i/incremental_minimum_spanning_forest.mojo),
[Nim](../../../nim/i/incremental_minimum_spanning_forest.nim),
[Odin](../../../odin/i/incremental_minimum_spanning_forest.odin),
[Rust](../../../rust/i/incremental_minimum_spanning_forest.rs),
[V](../../../v/i/incremental_minimum_spanning_forest.v),
and [Zig](../../../zig/i/incremental_minimum_spanning_forest.zig).

The byte-output runner registers the primary model and validates port
presence; the verifier registers the independent model and defines
cross-reference cases, including all insertion orders of a triangle with a
parallel edge and a self-loop, and the maximum-sized input and output. These
checks are written but have not been run.

**Remaining:** verify the drafts when execution is permitted. No compiler,
validator, test, or benchmark has been run.
