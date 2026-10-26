# GBBS SCAN structural clustering

This package implements a bounded deterministic profile of GBBS's
index-based SCAN clustering. It uses the default unweighted cosine structural
similarity and the source's deterministic non-core attachment mode.

## Bounded contract

- Exported symbol: `gbbs_scan_structural_clustering`; ABI:
  `i64_array_bytes_output`.
- Input: `[node_count, edge_count, (u, v)...]` for a simple undirected graph.
  Each edge is supplied once as `u < v`; self-loops and duplicate edges are
  invalid. Bounds are 1–16 vertices and 0–64 edges; length must be exactly
  `2 + 2*edge_count`.
- Fixed source parameters: `mu=3`, `epsilon=0.5`. For adjacent vertices,
  similarity is the cosine of their closed-neighborhood indicator vectors:
  `(common open neighbors + 2) / sqrt((degree(u)+1)*(degree(v)+1))`.
  A vertex is core when at least two neighbors meet epsilon. Core vertices are
  clustered by connected components over epsilon-similar core edges.
- A non-core vertex chooses its epsilon-similar core neighbor with greatest
  cosine similarity; ties choose the lowest core vertex ID. Component labels
  are canonicalized to the smallest core ID in each component. A vertex with
  no eligible core neighbor is output as `-1` (the source's unclustered
  sentinel).
- Output is one little-endian signed i64 label per vertex. Success returns
  `8*node_count` bytes. Malformed input returns `-1`; null output or
  insufficient capacity returns `-2` without writing.
- Projection: the source accepts arbitrary `mu` and `epsilon`, but this profile
  fixes both to keep one bounded workload. The source uses `float`; the ports
  compare the fixed half-threshold and candidate similarities with exact
  integer-square comparisons. Core components are labeled by minimum vertex ID
  rather than the source's implementation-dependent union-find root. The
  source's deterministic non-core rule (maximum similarity, then minimum core
  ID) is retained.

## Source and variant crosswalk

Pinned to [ParAlg/gbbs commit
`dbd1dcad582c0a316c5ba0d5524319d596dd82da`](https://github.com/ParAlg/gbbs/tree/dbd1dcad582c0a316c5ba0d5524319d596dd82da).
The selected operation is in
[`IndexBased/scan.cc`](https://github.com/ParAlg/gbbs/blob/dbd1dcad582c0a316c5ba0d5524319d596dd82da/benchmarks/SCAN/IndexBased/scan.cc)
and [`IndexBased/scan.h`](https://github.com/ParAlg/gbbs/blob/dbd1dcad582c0a316c5ba0d5524319d596dd82da/benchmarks/SCAN/IndexBased/scan.h);
cosine similarity and deterministic attachment are defined in
[`IndexBased/similarity_measure.h`](https://github.com/ParAlg/gbbs/blob/dbd1dcad582c0a316c5ba0d5524319d596dd82da/benchmarks/SCAN/IndexBased/similarity_measure.h)
and `IndexBased/scan.cc::AttachNoncoresToClustersDeterministic`.

The `Naive` implementation uses the same closed-neighborhood cosine threshold,
core rule, and core connected components. Its output allows a border vertex to
belong to every adjacent core cluster, while the selected IndexBased
deterministic mode chooses one best adjacent core. This package covers that
single-cluster deterministic profile; it does not count the two source
directories as separate algorithm families.

GBBS is MIT licensed. Its complete notice is retained in [LICENSE.txt](LICENSE.txt);
the nine language ports are clean-room implementations.

## Ports

| Language | Source |
| --- | --- |
| C | [c/g/gbbs_scan_structural_clustering.c](../../../c/g/gbbs_scan_structural_clustering.c) |
| C3 | [c3/g/gbbs_scan_structural_clustering.c3](../../../c3/g/gbbs_scan_structural_clustering.c3) |
| C++ | [cpp/g/gbbs_scan_structural_clustering.cpp](../../../cpp/g/gbbs_scan_structural_clustering.cpp) |
| Elisa | [elisa/g/gbbs_scan_structural_clustering.elisa](../../../elisa/g/gbbs_scan_structural_clustering.elisa) |
| Nim | [nim/g/gbbs_scan_structural_clustering.nim](../../../nim/g/gbbs_scan_structural_clustering.nim) |
| Odin | [odin/g/gbbs_scan_structural_clustering.odin](../../../odin/g/gbbs_scan_structural_clustering.odin) |
| Rust | [rust/g/gbbs_scan_structural_clustering.rs](../../../rust/g/gbbs_scan_structural_clustering.rs) |
| V | [v/g/gbbs_scan_structural_clustering.v](../../../v/g/gbbs_scan_structural_clustering.v) |
| Zig | [zig/g/gbbs_scan_structural_clustering.zig](../../../zig/g/gbbs_scan_structural_clustering.zig) |

Fixtures are in [workload.json](workload.json). The package oracle uses
adjacency sets and exact squared-score comparisons; the independent verifier
uses a dense adjacency matrix and direct cosine calculations.
