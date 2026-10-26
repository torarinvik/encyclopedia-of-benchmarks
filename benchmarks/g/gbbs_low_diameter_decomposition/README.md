# GBBS low-diameter decomposition

This bounded profile implements the MPX13 source's exponential center batches
and multi-source frontier growth for a simple undirected graph. Each vertex
returns the ID of its cluster center.

## Contract

- Exported symbol: `gbbs_low_diameter_decomposition`; ABI: `i64_array_bytes_output`.
- Input: `[node_count, edge_count, (u, v)...]`.
- Bounds: `1 <= node_count <= 12`, `0 <= edge_count <= 24`, and exact input
  length `2 + 2*edge_count`.
- The graph is simple and undirected. Each edge is provided once as `u < v`.
- Output is one byte per vertex, in vertex-ID order. Each byte is the vertex
  ID of its cluster center. Success returns `node_count`; invalid input
  returns -1; null output or insufficient capacity returns -2 without writing.
- Maximum input length is 50 integers; maximum output is 12 bytes.

The profile fixes the launcher default `beta=0.2` and disables its optional
random vertex permutation. It uses the source's batch sizes
`floor(exp(round*0.2))`, represented by the exact bounded table
`[1,1,1,1,2,2,3,4,4,6,7,9,11]`. Candidate vertices are considered in ascending
ID order. Each round adds any still-unassigned candidates from its batch, then
expands the current frontier by one graph edge. When several frontier vertices
reach one unassigned vertex in the same round, this deterministic projection
assigns the smallest center ID. Batch sizes are clipped at the vertex bound.
That tie rule and bounded clipping make the source's parallel scheduling
deterministic while preserving its center-batch and frontier-growth operation.
This fixed no-permutation profile does not claim the randomized decomposition
guarantee associated with permuted center selection.

This is distinct from BFS output trees and connected-component labels. It
partitions vertices into growing center-based clusters; a connected component
may contain several clusters, and disconnected components receive independent
centers. The profile exposes cluster IDs, whereas the GBBS launcher measures
time and optionally prints cluster statistics.

## Source and rights

The source is pinned to GBBS commit
[`dbd1dcad582c0a316c5ba0d5524319d596dd82da`](https://github.com/ParAlg/gbbs/tree/dbd1dcad582c0a316c5ba0d5524319d596dd82da):
[`LowDiameterDecomposition.h`](https://github.com/ParAlg/gbbs/blob/dbd1dcad582c0a316c5ba0d5524319d596dd82da/benchmarks/LowDiameterDecomposition/MPX13/LowDiameterDecomposition.h)
and
[`LowDiameterDecomposition.cc`](https://github.com/ParAlg/gbbs/blob/dbd1dcad582c0a316c5ba0d5524319d596dd82da/benchmarks/LowDiameterDecomposition/MPX13/LowDiameterDecomposition.cc).
The profile follows `generate_shifts`, `LDD_F`, and `LDD_impl`, with the
launcher defaults `beta=0.2` and no permutation. GBBS is MIT licensed; the full
notice is in `LICENSE.txt`. All nine language ports are clean-room
implementations.

## Ports

| Language | Source |
| --- | --- |
| C | `c/g/gbbs_low_diameter_decomposition.c` |
| C3 | `c3/g/gbbs_low_diameter_decomposition.c3` |
| C++ | `cpp/g/gbbs_low_diameter_decomposition.cpp` |
| Elisa | `elisa/g/gbbs_low_diameter_decomposition.elisa` |
| Nim | `nim/g/gbbs_low_diameter_decomposition.nim` |
| Odin | `odin/g/gbbs_low_diameter_decomposition.odin` |
| Rust | `rust/g/gbbs_low_diameter_decomposition.rs` |
| V | `v/g/gbbs_low_diameter_decomposition.v` |
| Zig | `zig/g/gbbs_low_diameter_decomposition.zig` |

The source-stage oracle models center batches and frontier waves. The
independent verifier uses all-pairs graph distances and the scheduled release
round for every candidate center.
