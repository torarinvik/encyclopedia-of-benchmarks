# Minimum-weight dominating set of a tree

A dominating set contains or neighbors every vertex. This profile minimizes
the sum of selected nonnegative vertex weights on a rooted tree; selected
vertices need not induce a connected graph. A bottom-up dynamic program keeps
three states per vertex: selected, unselected but dominated by a child, and
unselected while waiting for the parent to dominate it. Merging a child either
maintains or establishes the selected-child condition.

Input is `[n,parent[1..n-1],weights[0..n-1]]`, with `1 <= n <= 64`,
`0 <= parent[v] < v`, and weights in `0..1000000`. Exact length is `2*n`,
at most 128 words; 129 is the parseable malformed-frame limit. Return the
minimum weight in `0..64000000`, or `-1` for invalid or null input. A
single-vertex tree must select its only vertex.

The DP uses `O(n)` time and space. The existing
[`weighted_connected_dominating_set`](../../w/weighted_connected_dominating_set/README.md)
requires connected selected vertices and enumerates general-graph subsets;
[`tree_weighted_vertex_cover`](../tree_weighted_vertex_cover/README.md) covers
edges and uses two states. The [INRIA examination](https://www-sop.inria.fr/members/Nicolas.Nisse/finalExam2024.pdf)
identifies the weighted tree DP; the contract, source and fixtures are
independently authored and no source prose or code is copied. Drafts in all ten
languages and the references are uncompiled and unrun. A workload, rights note,
package checker and scalar-suite wiring are drafted; the verifier source
specifies exhaustive small trees and maximum-size paths and stars. The workload
includes separately selected branches and a selected grandchild case. Elisa uses a
bounded view after its ABI guard. Nothing has been executed.
