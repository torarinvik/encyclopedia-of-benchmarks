# Minimum distance-k domination of a tree

Select as few vertices as possible so every vertex lies at distance at most
`k` from a selected vertex. The draft repeatedly chooses a deepest uncovered
vertex, places a center at its `k`-th ancestor (or at the root if the path is
shorter), and marks all vertices within radius `k`. Ties between equally deep
uncovered vertices use the lowest vertex ID.

Input is `[n,k,parent[1..n-1]]`, with `1 <= n <= 64`, `0 <= k <= 63`, and
`0 <= parent[v] < v`. Exact length is `n+1`, at most 65 words; 66 is the
parseable malformed-frame limit. Return the minimum number of centers in
`1..n`, or `-1` for invalid or null input. Radius zero requires every vertex.

The bounded implementation scans for the deepest uncovered vertex and performs
a breadth-first radius marking after each placement. It uses `O(n²)` time and
`O(n)` space for parent and child links; this is not a claim of
the faster or distributed protocols in the literature. The existing
[`tree_weighted_dominating_set`](../tree_weighted_dominating_set/README.md)
uses weighted distance-one domination and a different tree DP. The
[distance-`k` paper](https://ftp.gwdg.de/pub/misc/EMIS/journals/JGAA/accepted/2015/TurauKoehler2015.19.1.pdf)
also describes this sequential placement strategy and proves its optimality
for positive `k`. At radius zero every vertex must be selected. The independent
implementation uses parent/child links and breadth-first marking; no source
code, prose or examples are copied.
Contract and drafts are independently authored. Drafts in all ten languages and
the references are present; Elisa uses a bounded view after its ABI guard.
A workload, rights note, inventory checker and scalar-suite wiring are drafted;
the verifier source specifies exhaustive small trees and full-size paths and
stars. Nothing has been compiled or run.
