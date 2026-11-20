# Minimum-weight edge dominating set of a tree

Select tree edges of minimum total nonnegative weight such that every edge is
selected or shares an endpoint with a selected edge. This is distinct from
vertex domination and from maximum-weight matching: selected edges may touch.

The proposed scalar input is `[n, parent[1..n-1], weight[1..n-1]]`, with
`1 <= n <= 64`, `0 <= parent[v] < v`, and edge weights in `0..1000000`.
Its exact length is `2*n-1`; lengths through 128 are parseable. Return the
minimum cost, or `-1` for invalid or null input. The edgeless one-vertex tree
has cost zero. The maximum valid result is at most 63000000.

The reference uses a linear-time bottom-up tree DP. For each vertex, `S`
requires a selected child edge; `U` selects no child edge and requires each
child edge to be dominated from its child's side; and `P` selects no child
edge but permits incident child edges to await a selected parent edge. In `S`,
at least one child edge is selected. For a child edge, selecting it permits the
child's `S` or `P` state; skipping it permits `S` or `U` when another selected
edge touches the parent. State `U` requires `S` for every child, and the root
answer is `min(S,U)`. The implementation aggregates these states in `O(n)`
time and `O(n)` space. A separate exhaustive edge-subset oracle
is restricted to at most 16 vertices. The formulation is independently
written; related weighted edge domination on trees is studied in
[Linear Time Algorithms for Generalized Edge Dominating Set Problems](https://doi.org/10.1007/11534273_21).

Ports in all ten languages, a workload, a package checker, and scalar-suite
wiring are drafted. The verifier specifies exhaustive small trees and
maximum-size path and star cases. No source or checks have been executed;
the implementations and suite integration remain unverified.
