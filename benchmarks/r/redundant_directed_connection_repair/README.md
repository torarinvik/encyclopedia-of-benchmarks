# Redundant directed connection repair

An outward-directed rooted tree has one root of indegree zero and every other
vertex has one parent. This profile receives such a tree plus one additional
directed edge and identifies the last input edge whose removal restores a
rooted arborescence. It is distinct from
[`redundant_connection`](../redundant_connection/README.md), which detects an
extra edge in an undirected graph with disjoint sets.

## Contract

The exported `redundant_directed_connection_repair` function uses
`i64_array_scalar`. Input is `[n,(u,v)*n]`, with `3<=n<=16`, labels in
`[0,n)`, no self-loops or duplicate directed edges, and exact length `1+2*n`.
The valid graph is guaranteed to be a rooted directed tree plus one previously
absent directed edge. Return the zero-based index of the last input edge whose
removal leaves a rooted arborescence. A null, malformed, duplicate-edge, or
out-of-range input returns `-1`. The maximum valid and parseable frames are 33
and 34 words.

The primary first finds whether one vertex has two incoming edges. It skips
the later one and runs DSU cycle detection on the remaining undirected edge
set. A cycle selects the earlier incoming edge when there was a two-parent
conflict, or the cycle-closing edge otherwise. If no cycle remains, the
skipped later incoming edge is the answer. DSU repair takes `O(n alpha(n))`;
total time is `O(n^2)` because duplicate directed pairs are rejected during
input validation. Space is `O(n)`.

The independent reference removes candidate edges from last to first and
checks indegrees, unique-root reachability, and the remaining edge count
directly.

## Sources and rights

The [official LeetCode 685 title and directed-tree specification](https://leetcode.com/problems/redundant-connection-ii/)
were used for discovery only. The two-parent and DSU cycle cases are described
in the independent [GeeksforGeeks method reference](https://www.geeksforgeeks.org/dsa/extra-edge-in-a-directed-rooted-tree/);
DSU details are cross-checked with [CP-Algorithms](https://cp-algorithms.com/data_structures/disjoint_set_union.html).
No problem wording, examples, tests, submission, or code is reused. See
[`RIGHTS.md`](RIGHTS.md).

## Artifacts

- [`workload.json`](workload.json): bounded scalar fixtures.
- [`primary_oracle.py`](primary_oracle.py): parent-conflict plus DSU method.
- [`independent_oracle.py`](independent_oracle.py): deletion and arborescence validation.
- [`verify_workload.py`](verify_workload.py): static metadata, fixture, oracle, and port review.
- [`INVENTORY.md`](INVENTORY.md): source inventory.

Shared runner and catalog integration is maintained separately.
