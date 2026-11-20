# Minimum-cost sibling-distinct tree coloring

For a rooted tree, assign one of `k` labeled colors to each vertex. A child
must differ from its parent, and children of the same parent must have
pairwise distinct colors. Minimize the sum of the vertex-specific color costs.
Grandparent and grandchild colors may coincide. This is stronger than
[`tree_min_cost_proper_coloring`](../tree_min_cost_proper_coloring/README.md),
which permits equal sibling colors. The existing edge-coloring benchmark has
shared per-color costs and no root vertex color.

The planned scalar ABI input is `[n,k,parent[1..n-1],costs...]`, with
`1 <= n <= 32`, `1 <= k <= 10`, `0 <= parent[v] < v`, and `n*k` row-major
costs in `0..1000000`. Exact length is `n+1+n*k`, at most 353 words; the
parseable limit is 354. Return the minimum cost, `-2` if no coloring exists,
or `-1` for malformed or null input. Validation precedes infeasibility.
The parent indices place every parent before its child, allowing the draft to
process vertices in reverse index order without constructing a traversal.

The bounded draft computes subtree costs for each vertex color. For a fixed
parent color it assigns distinct remaining colors to children with a subset
DP; it does not enumerate complete tree colorings. Scanning the parent list
for each vertex and color adds `O(n²*k)` work, for total time
`O(n²*k + n*k*k*2^k)` and `O(n*k + 2^k)` working storage. An independently
written rectangular-assignment reference and exhaustive small-tree
cross-check source are also drafted.

A valid coloring exists exactly when every vertex has at most `k-1` children:
once its color is fixed, those children can take distinct colors from the
remaining `k-1`, independently of other sibling groups. Every feasible total
is at most 32,000,000, below the drafts' infeasibility sentinel of 10^12.

The [CP-Algorithms Hungarian-algorithm article](https://cp-algorithms.com/graph/hungarian-algorithm.html)
suggests an assignment-based tree-coloring construction. Its stated ordinary
proper-coloring problem does not require sibling colors to differ; this package
explicitly defines the stronger constraint instead. Only the mathematical idea
is used; the contract and draft are independently written.

Status: all ten language drafts, rectangular-assignment reference, workload,
package inventory checker, and scalar runner/verifier wiring are drafted. The
verifier source also specifies exhaustive small-tree comparisons against a
complete-coloring enumerator. All checks and drafts remain unexecuted.

Language drafts: [C](../../../c/t/tree_sibling_distinct_cost_coloring.c),
[C3](../../../c3/t/tree_sibling_distinct_cost_coloring.c3),
[C++](../../../cpp/t/tree_sibling_distinct_cost_coloring.cpp),
[Elisa](../../../elisa/t/tree_sibling_distinct_cost_coloring.elisa),
[Mojo](../../../mojo/t/tree_sibling_distinct_cost_coloring.mojo),
[Nim](../../../nim/t/tree_sibling_distinct_cost_coloring.nim),
[Odin](../../../odin/t/tree_sibling_distinct_cost_coloring.odin),
[Rust](../../../rust/t/tree_sibling_distinct_cost_coloring.rs),
[V](../../../v/t/tree_sibling_distinct_cost_coloring.v), and
[Zig](../../../zig/t/tree_sibling_distinct_cost_coloring.zig).
