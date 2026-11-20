# Minimum-weight total dominating set of a tree

A total dominating set must give every vertex a selected neighbor. Unlike
ordinary domination, a selected vertex cannot dominate itself. This profile
minimizes the sum of nonnegative selected weights on a rooted tree. A bottom-up
DP records whether the vertex and its parent are selected, and tracks whether
at least one child is selected. Selected vertices need not be connected.

Input is `[n,parent[1..n-1],weights[0..n-1]]`, with `1 <= n <= 64`,
`0 <= parent[v] < v`, and weights in `0..1000000`. Exact length is `2*n`,
at most 128 words; 129 is the parseable malformed-frame limit. Return the
minimum weight in `0..64000000`, `-2` for the single-vertex tree (which has no
neighbor), and `-1` for invalid or null input. Validate the entire frame before
returning infeasibility.

The DP takes `O(n)` time and space. The existing
[`tree_weighted_dominating_set`](../tree_weighted_dominating_set/README.md)
uses closed neighborhoods, while
[`weighted_connected_dominating_set`](../../w/weighted_connected_dominating_set/README.md)
uses ordinary domination with a connectedness constraint. The [total
f-domination paper](https://www.sciencedirect.com/science/article/pii/S0166218X18306309)
identifies linear weighted tree DP; this is its `f=1` objective, not a claim to
implement its full general formulation. Mathematical ideas only; no source
text, code or examples are copied. Reference drafts and all ten language drafts
are uncompiled and unrun. Elisa uses bounded views after its ABI guard. A
workload, rights note, package checker and scalar-suite wiring are drafted;
the verifier source specifies exhaustive small trees and full-size shapes.
Nothing has been executed.
