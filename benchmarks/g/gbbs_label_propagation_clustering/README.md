# GBBS one-sweep label-propagation clustering

This package captures the unweighted label update in GBBS's
`LabelPropagation` kernel. Vertices start with their own IDs as labels. Each
vertex adopts the most common current label among its neighbors; when counts
tie, the source's descending `(weight, label)` ordering chooses the larger
label. Updates become visible immediately to later vertices in the sweep.

## Bounded contract

- Exported symbol: `gbbs_label_propagation_clustering`; ABI:
  `i64_array_bytes_output`.
- Input: `[node_count, edge_count, (u, v)...]` describing a simple undirected
  unweighted graph. Each edge appears once with `u < v`; disconnected and
  edgeless graphs are valid.
- Bounds: `1 <= node_count <= 16`, `0 <= edge_count <= 64`, exact length
  `2 + 2*edge_count`.
- Operation: initialize labels to vertex IDs and perform one asynchronous
  sweep in ascending vertex order. An isolated vertex keeps its label. Output
  is one little-endian signed i64 label per vertex; success returns
  `8*node_count` bytes. Malformed input returns `-1`; null output or
  insufficient capacity returns `-2` without writing.
- Projection: GBBS's launcher defaults to asynchronous updates and as many as
  100 iterations. This deterministic profile fixes the update schedule to one
  ascending-ID sweep while keeping in-sweep label changes visible to later
  vertices. It excludes weighted graphs, graph-coloring mode, parallel
  scheduling, and later convergence sweeps.

## Source and rights

The source is pinned to
[ParAlg/gbbs commit `dbd1dcad582c0a316c5ba0d5524319d596dd82da`](https://github.com/ParAlg/gbbs/tree/dbd1dcad582c0a316c5ba0d5524319d596dd82da).
The launcher is
[`LabelPropagation.cc::LabelPropagation_runner`](https://github.com/ParAlg/gbbs/blob/dbd1dcad582c0a316c5ba0d5524319d596dd82da/benchmarks/Clustering/LabelPropagation/LabelPropagation.cc);
the update and tie semantics are in
[`LabelPropagation.h::LabelPropagation` and `internal::compute_new_color`](https://github.com/ParAlg/gbbs/blob/dbd1dcad582c0a316c5ba0d5524319d596dd82da/benchmarks/Clustering/LabelPropagation/LabelPropagation.h).
The repository is MIT licensed. The full notice is retained in
[LICENSE.txt](LICENSE.txt); all ports are clean-room implementations.

## Ports

| Language | Source |
| --- | --- |
| C | [c/g/gbbs_label_propagation_clustering.c](../../../c/g/gbbs_label_propagation_clustering.c) |
| C3 | [c3/g/gbbs_label_propagation_clustering.c3](../../../c3/g/gbbs_label_propagation_clustering.c3) |
| C++ | [cpp/g/gbbs_label_propagation_clustering.cpp](../../../cpp/g/gbbs_label_propagation_clustering.cpp) |
| Elisa | [elisa/g/gbbs_label_propagation_clustering.elisa](../../../elisa/g/gbbs_label_propagation_clustering.elisa) |
| Nim | [nim/g/gbbs_label_propagation_clustering.nim](../../../nim/g/gbbs_label_propagation_clustering.nim) |
| Odin | [odin/g/gbbs_label_propagation_clustering.odin](../../../odin/g/gbbs_label_propagation_clustering.odin) |
| Rust | [rust/g/gbbs_label_propagation_clustering.rs](../../../rust/g/gbbs_label_propagation_clustering.rs) |
| V | [v/g/gbbs_label_propagation_clustering.v](../../../v/g/gbbs_label_propagation_clustering.v) |
| Zig | [zig/g/gbbs_label_propagation_clustering.zig](../../../zig/g/gbbs_label_propagation_clustering.zig) |

Fixtures are in [workload.json](workload.json). The package oracle aggregates
adjacency-list label frequencies; the independent verifier recounts labels
from a dense adjacency matrix.
