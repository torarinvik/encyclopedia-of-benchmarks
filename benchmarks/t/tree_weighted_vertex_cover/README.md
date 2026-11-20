# Minimum-weight vertex cover of a tree

A vertex cover selects vertices so every edge has a selected endpoint. This
profile computes the minimum sum of nonnegative selected vertex weights using
bottom-up included/excluded dynamic-programming states. If a vertex is omitted,
each child must be included; otherwise each child takes its cheaper state.

Input is `[n,parent[1..n-1],weights[0..n-1]]`, with `1 <= n <= 64`,
`0 <= parent[v] < v`, and weights in `0..1000000`. Exact length is `2*n`,
at most 128 words; 129 is the parseable malformed-frame limit. Return the
minimum weight in `0..64000000`, or `-1` for invalid or null input. A
single-vertex tree has optimum zero.

The DP uses `O(n)` time and space. [`tree_matching`](../tree_matching/README.md)
optimizes nonincident weighted edges instead, and
[`vertex_cover_search_trees`](../../v/vertex_cover_search_trees/README.md)
uses branching on general unweighted graphs. The complement of a vertex cover
is an independent set, so this profile also supplies the corresponding
maximum-weight tree independent-set value by subtracting from the total weight;
the existing [`maximum_independent_set`](../../m/maximum_independent_set/README.md)
is an unweighted general-graph branch-and-bound kernel. A second one-shot tree
package using this recurrence would duplicate the static computation; a
separate HLD/max-plus profile for point updates is reserved. The [INRIA lecture
notes](https://www-sop.inria.fr/members/Nicolas.Nisse/LectureGraphAlgo.pdf)
provide the mathematical idea only; the contract and code are independently
authored. Two reference drafts and drafts in all ten languages are uncompiled
and unrun. Elisa uses a bounded view after its ABI guard. An independently
authored workload, rights note, inventory checker and scalar-suite wiring are
drafted; verifier source specifies small exhaustive trees and maximum-size
chains and stars. Nothing has been executed.
