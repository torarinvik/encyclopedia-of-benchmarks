# General weighted matching by primal-dual blossom

This profile computes the maximum total edge weight in a simple undirected
graph using Edmonds' weighted blossom algorithm. The primal-dual search keeps
vertex and odd-blossom dual labels, explores tight edges in an alternating
forest, contracts odd blossoms, and expands inner blossoms when their dual
slack reaches zero. When an exposed-root dual reaches zero, the current
matching is optimal. The resulting bounded implementation runs in
`O(N^3)` time and uses fixed-size graph and blossom workspaces.

The algorithm reference is Korte and Vygen, [“Weighted Matching,”
*Combinatorial Optimization*, Chapter 11](https://doi.org/10.1007/978-3-662-21711-5_11).
The publisher describes extending Edmonds' cardinality algorithm to weighted
nonbipartite matching and gives an `O(n^3)` implementation. The benchmark also
uses the [Library Checker task](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/graph/general_weighted_matching/task.md)
as an operation and weight-domain reference. Both sources provide algorithmic
ideas and task semantics only; all implementations and fixtures are written
independently.

## Contract

Input is a signed-i64 array `[N, M, u0, v0, w0, ...]`. The graph is simple,
undirected, and has `1 <= N <= 64`, `0 <= M <= N*(N-1)/2`, and edge weights
`1..=1,000,000`. Each edge has distinct, in-range endpoints; any repeated
unordered pair is invalid. The packed array must contain exactly `2 + 3*M`
words. Return the maximum total matching weight as a signed i64; malformed
input returns `-2`. The empty matching is permitted and has value zero.

The existing [`general_weighted_matching`](../general_weighted_matching/README.md)
profile uses exact subset DP and is bounded to 16 vertices. This package is a
separate primal-dual blossom kernel with polynomial scaling through 64
vertices. Its scalar result leaves the chosen matching unconstrained when
several optima exist.

## References and workload

- Primary small-graph reference: [`primary_oracle.py`](primary_oracle.py), a
  bottom-up subset recurrence.
- Independent small-graph reference: [`independent_oracle.py`](independent_oracle.py),
  which enumerates edge subsets on the small fixture domain. Both references
  use hand-derived objective cases for the larger bounded fixtures.
- Cases and bounds: [`workload.json`](workload.json).
- Clean-room provenance: [`RIGHTS.md`](RIGHTS.md).
- Static source inventory: [`INVENTORY.md`](INVENTORY.md).

## Language ports

| Language | Source |
|---|---|
| C | [`c/g/general_weighted_matching_primal_dual_blossom.c`](../../../c/g/general_weighted_matching_primal_dual_blossom.c) |
| C3 | [`c3/g/general_weighted_matching_primal_dual_blossom.c3`](../../../c3/g/general_weighted_matching_primal_dual_blossom.c3) |
| C++ | [`cpp/g/general_weighted_matching_primal_dual_blossom.cpp`](../../../cpp/g/general_weighted_matching_primal_dual_blossom.cpp) |
| Elisa | [`elisa/g/general_weighted_matching_primal_dual_blossom.elisa`](../../../elisa/g/general_weighted_matching_primal_dual_blossom.elisa) |
| Mojo | [`mojo/g/general_weighted_matching_primal_dual_blossom.mojo`](../../../mojo/g/general_weighted_matching_primal_dual_blossom.mojo) |
| Nim | [`nim/g/general_weighted_matching_primal_dual_blossom.nim`](../../../nim/g/general_weighted_matching_primal_dual_blossom.nim) |
| Odin | [`odin/g/general_weighted_matching_primal_dual_blossom.odin`](../../../odin/g/general_weighted_matching_primal_dual_blossom.odin) |
| Rust | [`rust/g/general_weighted_matching_primal_dual_blossom.rs`](../../../rust/g/general_weighted_matching_primal_dual_blossom.rs) |
| V | [`v/g/general_weighted_matching_primal_dual_blossom.v`](../../../v/g/general_weighted_matching_primal_dual_blossom.v) |
| Zig | [`zig/g/general_weighted_matching_primal_dual_blossom.zig`](../../../zig/g/general_weighted_matching_primal_dual_blossom.zig) |

Suite integration hook: register symbol `general_weighted_matching_primal_dual_blossom`
and the scalar fixtures with the `i64_array_scalar` suite. Shared suite files
and root catalog documents are left to root integration.
