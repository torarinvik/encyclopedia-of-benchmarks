# Rights and provenance

The operation was identified from the public LeetCode title “Find Critical
and Pseudo-Critical Edges in Minimum Spanning Tree.” Only that title index
entry was used for discovery; no LeetCode problem text, examples, tests, submissions,
or source code were consulted or reused.

The benchmark method is a clean-room derivation combining Kruskal's
minimum-spanning-tree ordering with edge-ID-aware bridge checks in the
equal-weight contracted graph. Its algorithm references are
[CP-Algorithms: Kruskal minimum spanning tree](https://cp-algorithms.com/graph/mst_kruskal.html)
and [CP-Algorithms: finding bridges](https://cp-algorithms.com/graph/bridge-searching.html).
CP-Algorithms is licensed CC BY-SA 4.0. No source code, prose, or test data
from those pages was copied; only their high-level algorithm descriptions
were consulted. The independent oracle is a separately structured
force/forbid Kruskal recomputation.
