# GBBS k-core decomposition

This package implements the bounded core-number operation from ParAlg/GBBS
`KCore`. For every vertex, it returns the largest `k` for which that vertex
belongs to a subgraph whose vertices each have at least `k` neighbors inside
that subgraph. This is a distinct peeling algorithm, not connected-component
labeling or degeneracy-order output.

## Contract

- Exported symbol: `gbbs_k_core_decomposition`; ABI: `i64_array_bytes_output`.
- Input: `[node_count, edge_count, (u, v)...]`. Edges are undirected and
  represented once with `u < v`; self-loops and duplicate edges are invalid.
- Bounds: `1 <= node_count <= 16`, `0 <= edge_count <= 64`, and exact input
  length `2 + 2*edge_count`.
- Output: one little-endian signed 64-bit core number per vertex in ascending
  vertex order. Success returns `8*node_count`; malformed input returns `-1`;
  null output or insufficient capacity returns `-2` without writing.
- The ports construct a symmetric adjacency matrix, repeatedly remove the
  complete current minimum-degree shell, and lower surviving neighbor degrees
  by the number of removed incident edges, clamping each result to the current
  shell number. Equal-degree vertices are processed in vertex order. This is a
  deterministic sequential projection of GBBS's increasing degree-bucket
  `KCore` kernel; bucket scheduling, parallel edge maps, graph loading, and
  timing output are omitted.

The package oracle independently computes each vertex's core number by
enumerating all induced vertex subsets containing it. The byte-suite verifier
uses threshold peeling. Both validate the same simple-undirected graph input.

## Source and rights

Behavior source: [`KCore.h::KCore`](https://github.com/ParAlg/gbbs/blob/dbd1dcad582c0a316c5ba0d5524319d596dd82da/benchmarks/KCore/JulienneDBS17/KCore.h), pinned to GBBS commit
`dbd1dcad582c0a316c5ba0d5524319d596dd82da`. The launcher
[`KCore.cc::KCore_runner`](https://github.com/ParAlg/gbbs/blob/dbd1dcad582c0a316c5ba0d5524319d596dd82da/benchmarks/KCore/JulienneDBS17/KCore.cc)
selects the bucketed `KCore` path by default; its `-fa` alternative is outside
this profile. GBBS is MIT licensed; the full notice is in [`LICENSE.txt`](LICENSE.txt).
All nine language implementations are clean-room ports.

## Ports

| Language | Source |
| --- | --- |
| C | [`c/k/gbbs_k_core_decomposition.c`](../../../c/k/gbbs_k_core_decomposition.c) |
| C3 | [`c3/k/gbbs_k_core_decomposition.c3`](../../../c3/k/gbbs_k_core_decomposition.c3) |
| C++ | [`cpp/k/gbbs_k_core_decomposition.cpp`](../../../cpp/k/gbbs_k_core_decomposition.cpp) |
| Elisa | [`elisa/k/gbbs_k_core_decomposition.elisa`](../../../elisa/k/gbbs_k_core_decomposition.elisa) |
| Nim | [`nim/k/gbbs_k_core_decomposition.nim`](../../../nim/k/gbbs_k_core_decomposition.nim) |
| Odin | [`odin/k/gbbs_k_core_decomposition.odin`](../../../odin/k/gbbs_k_core_decomposition.odin) |
| Rust | [`rust/k/gbbs_k_core_decomposition.rs`](../../../rust/k/gbbs_k_core_decomposition.rs) |
| V | [`v/k/gbbs_k_core_decomposition.v`](../../../v/k/gbbs_k_core_decomposition.v) |
| Zig | [`zig/k/gbbs_k_core_decomposition.zig`](../../../zig/k/gbbs_k_core_decomposition.zig) |

Fixtures: [`workload.json`](workload.json). Package oracle:
[`gbbs_k_core_decomposition_oracle.py`](../../gbbs_k_core_decomposition_oracle.py).
