# GraphAIBench heap-based complete-linkage graph HAC

This package isolates the launcher-default heap-based complete-linkage mode
from GraphAIBench's graph hierarchical agglomerative clustering. Each merge
selects the highest remaining edge similarity. When two clusters share a
neighbor, the merged edge keeps the minimum of their two similarities; a
one-sided edge is retained. The output is the source-shaped binary dendrogram,
with one (parent_id, merge_similarity) pair per leaf and internal node.

## Bounded contract

- Exported symbol: graphai_hac_complete_linkage; ABI:
  i64_array_bytes_output.
- Input: [node_count, edge_count, (u, v, weight)...]. Each edge is an
  undirected edge represented once with u < v; self-loops and duplicate
  edges are invalid.
- Bounds: 1 <= node_count <= 8, 0 <= edge_count <= 24, exact length
  2 + 3*edge_count, connected graph, edge weights in [1,32], and all input
  edge weights distinct. A one-vertex graph with no edges is valid.
- Output: (parent_id, merge_similarity) as two little-endian signed i64
  values for each of the 2*node_count-1 source dendrogram nodes, ordered by
  node ID. The root parent sentinel is UINT32_MAX (4294967295) and its
  similarity is zero. Success returns 16*(2*node_count-1) bytes; malformed
  input returns -1; null output or insufficient capacity returns -2
  without writing.
- Distinct edge weights remove merge-score ties, so the source's unspecified
  augmented-map tie selection cannot change the merge order. The ports replace
  the source heap with a deterministic full edge scan. They require connected
  input so the source's disconnected-component dendrogram fallback is outside
  the profile.

## Source and rights

The pinned launcher is src/clustering/main.cc::main, which selects
heap_based::HAC and "complete" linkage by default. The corresponding source
is src/clustering/HeapBased.h::HAC and src/clustering/ClusteredGraph.h::unite;
src/clustering/HAC_configuration.h supplies SimilarityClustering,
ActualWeight, and MinLinkage. This profile uses the source's maximum-edge
priority and minimum merge update with exact small integer weights. Source pin:
[chenxuhao/GraphAIBench commit 17834cb29b7c542481c2e3740dc9664841b72f59](https://github.com/chenxuhao/GraphAIBench/tree/17834cb29b7c542481c2e3740dc9664841b72f59).
The repository is MIT licensed; its full notice is retained in
[LICENSE.txt](LICENSE.txt). All ports are clean-room implementations.

## Ports

| Language | Source |
| --- | --- |
| C | [c/g/graphai_hac_complete_linkage.c](../../../c/g/graphai_hac_complete_linkage.c) |
| C3 | [c3/g/graphai_hac_complete_linkage.c3](../../../c3/g/graphai_hac_complete_linkage.c3) |
| C++ | [cpp/g/graphai_hac_complete_linkage.cpp](../../../cpp/g/graphai_hac_complete_linkage.cpp) |
| Elisa | [elisa/g/graphai_hac_complete_linkage.elisa](../../../elisa/g/graphai_hac_complete_linkage.elisa) |
| Nim | [nim/g/graphai_hac_complete_linkage.nim](../../../nim/g/graphai_hac_complete_linkage.nim) |
| Odin | [odin/g/graphai_hac_complete_linkage.odin](../../../odin/g/graphai_hac_complete_linkage.odin) |
| Rust | [rust/g/graphai_hac_complete_linkage.rs](../../../rust/g/graphai_hac_complete_linkage.rs) |
| V | [v/g/graphai_hac_complete_linkage.v](../../../v/g/graphai_hac_complete_linkage.v) |
| Zig | [zig/g/graphai_hac_complete_linkage.zig](../../../zig/g/graphai_hac_complete_linkage.zig) |

Workload fixtures and the package oracle are stored beside this README and in
../../graphai_hac_complete_linkage_oracle.py.
