# Cocomparability LDFS minimum path cover

This package computes the number of paths in the bounded LDFS-based minimum
path cover of a connected cocomparability graph. It accepts the graph's
cocomparability order as input, runs LDFS+ using that order, then makes the
Rightmost-Neighbor (RMN) sweep. Each outer RMN iteration starts one path; its
inner loop repeatedly chooses the current vertex's rightmost unvisited
neighbor. The exported result is the number of outer iterations.

## Contract

- Exported symbol: `cocomparability_ldfs_minimum_path_cover`; ABI:
  `i64_array_scalar`.
- Input: `[n, adjacency_mask[n], order[n]]`, where `1 <= n <= 8`. Bit `v` in
  `adjacency_mask[u]` means the undirected edge `{u,v}`. `order` lists
  vertex IDs from left to right in the supplied cocomparability ordering.
- The graph must be simple, undirected, and connected. Every row mask must
  have no out-of-range bits or diagonal bit, and the row masks must be
  symmetric. `order` must be a permutation of `0..n-1`.
- The supplied order is checked for the umbrella-free property: for every
  `i < j < k`, if `order[i]` is adjacent to `order[k]`, then it must be
  adjacent to `order[j]` or `order[j]` must be adjacent to `order[k]`.
- The exact input length is `1 + 2*n`; maximum valid and parseable lengths
  are 17 and 18 signed-i64 words. Null, malformed, disconnected, or
  non-umbrella-free input returns `-1`.
- A valid result is the number of paths, in `1..n`; the conservative scalar
  ceiling is 8. Fixed workspace is capped at 4,096 bytes.

## Search and tie rules

LDFS+ assigns every vertex an initially empty label. At each step it selects
an unvisited vertex with lexicographically largest label, breaking equal-label
ties by taking the rightmost vertex in the supplied order. It starts at that
order's rightmost vertex because all initial labels are empty. When it visits
vertex `v` at step `i`, it prepends `i` to each unvisited neighbor's label.
Labels are compared as newest-to-oldest integer sequences; if one is a prefix
of another, the longer label is larger.

RMN scans the resulting LDFS+ order from right to left. It starts a new path
at the rightmost unvisited vertex, then repeatedly follows the rightmost
unvisited neighbor in that order until the current vertex has no such
neighbor. The next outer iteration starts another path. This deterministic
cover has minimum cardinality for a supplied umbrella-free cocomparability
order. Connected inputs follow the stated input precondition of the LDFS+
procedure; they also keep the bounded profile aligned with its connected-graph
formulation.

The primary reference follows LDFS+ and RMN. The independent reference checks
the optimum by subset dynamic programming: it identifies every induced vertex
subset that has a Hamilton path, then partitions the full vertex set into the
fewest such subsets. Its time bound is `O(n*2^n + 3^n)` and space is `O(2^n)`.
The search port has `O(n^3)` time under the fixed label representation and
`O(n^2)` workspace. The graph class and umbrella-free ordering are part of the
input contract; the package does not search for such an order.

## Distinctness and sources

The local [`ldfs_ordering_certificate`](../../l/ldfs_ordering_certificate/README.md)
computes an LDFS ordering with four-vertex characterization witnesses. Its
README explicitly excludes the cocomparability minimum-path-cover
application. The local [`dag_minimum_path_cover`](../../d/dag_minimum_path_cover/README.md)
uses bipartite matching on a directed acyclic graph and emits a canonical
successor map. This package instead searches a connected undirected graph
under a supplied umbrella-free order and counts the paths from LDFS+ followed
by RMN.

The application and minimum-cover result are from Corneil, Dalton, and Habib,
[“LDFS-Based Certifying Algorithm for the Minimum Path Cover Problem on
Cocomparability Graphs”](https://doi.org/10.1137/11083856X), *SIAM Journal on
Computing* 42(3), 792–807 (2013). The corrigendum
[10.1137/20M1327835](https://doi.org/10.1137/20M1327835) repairs proof errors
and states that the algorithms are unchanged. The operational LDFS+ and RMN
tie rules are also stated as Algorithms 2 and 3 in Mertzios and Corneil,
[“A Simple Polynomial Algorithm for the Longest Path Problem on
Cocomparability Graphs”](https://doi.org/10.1137/100793529), §2, pp. 5–6. The
Encyclopedia crosswalk is Chapter 685,
[DOI 10.1007/978-1-4939-2864-4_685](https://doi.org/10.1007/978-1-4939-2864-4_685).
These sources provide algorithm descriptions and theorem attribution only;
the bounded contract, references, workload, and ports are clean-room.

See [RIGHTS.md](RIGHTS.md), [workload.json](workload.json),
[primary_oracle.py](primary_oracle.py),
[independent_oracle.py](independent_oracle.py), and
[verify_workload.py](verify_workload.py). The static file list is
[INVENTORY.md](INVENTORY.md). The shared `i64_array_scalar` runner and
verifier and the catalog now register this package.

## Ten language ports

| Language | Source |
|---|---|
| C | [c/c/cocomparability_ldfs_minimum_path_cover.c](../../../c/c/cocomparability_ldfs_minimum_path_cover.c) |
| C3 | [c3/c/cocomparability_ldfs_minimum_path_cover.c3](../../../c3/c/cocomparability_ldfs_minimum_path_cover.c3) |
| C++ | [cpp/c/cocomparability_ldfs_minimum_path_cover.cpp](../../../cpp/c/cocomparability_ldfs_minimum_path_cover.cpp) |
| Elisa | [elisa/c/cocomparability_ldfs_minimum_path_cover.elisa](../../../elisa/c/cocomparability_ldfs_minimum_path_cover.elisa) |
| Mojo | [mojo/c/cocomparability_ldfs_minimum_path_cover.mojo](../../../mojo/c/cocomparability_ldfs_minimum_path_cover.mojo) |
| Nim | [nim/c/cocomparability_ldfs_minimum_path_cover.nim](../../../nim/c/cocomparability_ldfs_minimum_path_cover.nim) |
| Odin | [odin/c/cocomparability_ldfs_minimum_path_cover.odin](../../../odin/c/cocomparability_ldfs_minimum_path_cover.odin) |
| Rust | [rust/c/cocomparability_ldfs_minimum_path_cover.rs](../../../rust/c/cocomparability_ldfs_minimum_path_cover.rs) |
| V | [v/c/cocomparability_ldfs_minimum_path_cover.v](../../../v/c/cocomparability_ldfs_minimum_path_cover.v) |
| Zig | [zig/c/cocomparability_ldfs_minimum_path_cover.zig](../../../zig/c/cocomparability_ldfs_minimum_path_cover.zig) |
