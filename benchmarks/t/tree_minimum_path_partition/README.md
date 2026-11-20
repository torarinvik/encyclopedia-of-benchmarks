# Minimum vertex-disjoint path partition of a tree

Partition the vertices of an undirected tree into the fewest vertex-disjoint
simple paths. A singleton vertex is a path. The scalar input is
`[n,parent[1..n-1]]`, where `1 <= n <= 64` and `0 <= parent[v] < v`.
The input has exactly `n` i64 words; lengths up to 65 are parseable. Return
the minimum number of paths, or `-1` for a null or invalid input.

Selecting the edges within the paths forms a spanning forest of maximum
degree two. Because a subgraph of a tree is acyclic, every component of such
a forest is a path. Its number of components is `n - selected_edges`, so a
minimum partition is a maximum-cardinality degree-two edge selection.

The planned linear-time tree DP stores the best selected-edge count in each
subtree with the parent edge either absent or present. For each child, skip
its connecting edge by default; selecting it changes the value by one plus
the child's parent-present state minus its parent-absent state. Add the best
one or two positive gains, according to whether the parent edge occupies a
degree slot. Space and time are `O(n)`. An independent exhaustive reference
enumerates edge subsets for small trees.

This is not maximum matching: on a three-vertex path, the optimum uses both
edges, whereas a matching can select only one. It is also distinct from a
directed DAG path cover because edge orientations do not constrain the path
partition. Related tree path-cover algorithms are studied in
[Optimal Hamiltonian completions and path covers for trees](https://www.cambridge.org/core/services/aop-cambridge-core/content/view/5F80A57D0F4918546ECDFFC4E32E874B/S1446181100013894a.pdf/div-class-title-optimal-hamiltonian-completions-and-path-covers-for-trees-and-a-reduction-to-maximum-flow-div.pdf).
Only the mathematical problem is used; the contract and models are
independently authored.

The contract, two reference models, ten language drafts, workload, rights note,
package checker, and scalar-suite wiring are present. Verifier source specifies
exhaustive small trees and full-size paths and stars. All remain unverified;
nothing has been compiled or executed.
