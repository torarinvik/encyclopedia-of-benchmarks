# Minimum-weight independent dominating set of a tree

Select vertices of minimum total weight so every vertex is selected or has a
selected neighbor, and no two selected vertices are adjacent. A bottom-up DP
uses selected, unselected-and-covered-by-child, and unselected-awaiting-parent
states. A selected parent may use only unselected child states, unlike ordinary
domination. The result is also a minimum-weight maximal independent set.

Input is `[n,parent[1..n-1],weights[0..n-1]]`, with `1 <= n <= 64`,
`0 <= parent[v] < v`, and weights in `0..1000000`. Exact length is `2*n`,
at most 128 words; 129 is the parseable malformed-frame limit. Return the
minimum weight in `0..64000000`, or `-1` for invalid or null input. The sole
vertex of a one-vertex tree must be selected.

The DP takes `O(n)` time and space. The existing
[`tree_weighted_dominating_set`](../tree_weighted_dominating_set/README.md)
permits adjacent selected vertices, and
[`tree_weighted_vertex_cover`](../tree_weighted_vertex_cover/README.md)
corresponds to a maximum-weight independent set without a domination condition.
The [tree domination research](https://www.opuscula.agh.edu.pl/vol45/6/art/opuscula_math_4540.pdf)
identifies independent domination and linear dynamic programming; the weighted
contract, code and fixtures here are independently authored. No source text or
code is copied. Reference drafts and all ten language drafts are uncompiled
and unrun. Workload, rights note, package checker and scalar-suite wiring are
drafted; verifier source specifies exhaustive small trees and full-size paths
and stars. Elisa uses a bounded view after its ABI guard. Nothing has been run.
