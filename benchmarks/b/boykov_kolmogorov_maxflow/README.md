# Boykov–Kolmogorov max-flow

Boykov–Kolmogorov (BK) max-flow grows reusable source and sink search trees,
augments when they meet, then repairs the resulting forests by adopting orphan
vertices. The tree reuse and orphan-repair stages distinguish it from the
repository's Dinic, Edmonds–Karp, and push-relabel profiles.

## Contract

- `i64_array_scalar` input is `[n,m,s,t,(u_0,v_0,c_0),...,(u_(m-1),v_(m-1),c_(m-1))]`.
- `2<=n<=8`, `0<=m<=16`, source and sink are distinct valid vertices, arcs have
  distinct endpoints, and capacities lie in `[0,15]`. Parallel and
  antiparallel arcs are allowed and their capacities are summed in the residual
  matrix. The frame must contain exactly `4+3m` words.
- Return the exact maximum flow, or `-1` for invalid input. The result is at
  most 240.

## Deterministic profile

- Initialize one source tree and one sink tree, with the FIFO active queue
  `[source,sink]`. Scan candidate neighbors in ascending vertex order.
- A source-tree vertex can grow over positive residual capacity `R[u][v]`; a
  sink-tree vertex grows backward over `R[v][u]`. A free vertex joins the
  growing tree and becomes active. Encountering the opposite tree selects the
  first bridge and stops growth.
- Requeue the active bridge endpoint before augmentation so it can resume
  scanning after the trees are repaired. Build the augmenting path from the
  two parent chains, push its bottleneck, and enqueue every saturated tree
  child as an orphan in source-to-sink path order.
- Adopt orphans FIFO. For each orphan, scan same-tree candidate parents by
  vertex ID and choose the first positive-residual edge whose parent chain still
  reaches the corresponding terminal through positive residual edges. If no
  parent qualifies, free the orphan, activate same-tree neighbors with a
  positive parent-to-orphan residual edge, and enqueue its former children as
  orphans in vertex order.
- Keep active/passive state when an orphan adopts a replacement parent; freeing
  a node removes it from the active queue.

This fixes the source/sink symmetry, scan order, active scheduling, bridge tie,
and adoption tie choices left open by the general algorithm. The profile has at
most 240 unit-or-larger augmentations, O((C+1)n^4) bounded worst-case time for
`C<=240`, and O(n^2+m) auxiliary storage.

## Workload and references

The primary oracle implements the two-tree grow/augment/adopt process. An
independent oracle enumerates all source-side cuts and returns their minimum
capacity. The workload includes disconnected, parallel, antiparallel,
multi-path, and orphan-repair networks plus invalid frames.

- Boykov and Kolmogorov, [An Experimental Comparison of Min-Cut/Max-Flow
  Algorithms for Energy Minimization](https://doi.org/10.1109/TPAMI.2004.60),
  especially the grow, augmentation, and adoption phases.
- [Boost.Graph Boykov–Kolmogorov algorithm description](https://www.boost.org/doc/libs/develop/libs/graph/doc/html/graph/algorithms/network_flow/boykov_kolmogorov_max_flow.html).
