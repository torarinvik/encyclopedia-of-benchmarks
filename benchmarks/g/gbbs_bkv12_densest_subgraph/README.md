# GBBS BKV12 approximate densest subgraph

This package profiles GBBS `WorkEfficientDensestSubgraph` from the BKV12
directory. It uses repeated density-threshold rounds: measure the current
induced average degree, remove every remaining vertex whose degree is at most
`(1 + epsilon)` times that average, and update degrees of the surviving graph.
The result is the largest average degree observed at a round boundary. The
launcher default is `epsilon=0.001`.

This is algorithmically distinct from the local
[`gbbs_charikar_densest_subgraph`](../gbbs_charikar_densest_subgraph/README.md)
profile. Charikar removes minimum-degree shells and evaluates every induced
suffix of that order; BKV12 removes a threshold-selected batch and only scores
the states between batches. Both return a density score for the same objective.

## Contract

- Exported symbol: `gbbs_bkv12_densest_subgraph`; ABI: `i64_array_float64`.
- Input: `[node_count, edge_count, (u, v)...]`; every simple undirected edge is
  listed once with `u < v`.
- Bounds: `1 <= node_count <= 16`, `0 <= edge_count <= 64`, exact length
  `2 + 2*edge_count`.
- Output: a binary64 maximum average-degree score. Malformed input returns
  `-1e300`.
- The source stores a symmetric graph, so its edge count and degree sum count
  both orientations. The profile uses the equivalent `2*undirected_edges`
  accounting and exact integer comparison for the decimal epsilon `0.001`:
  `1000*degree*remaining_vertices <= 1001*remaining_degree_sum`.
- Graph loading, parallel edge-map scheduling, debug output, and timing are
  excluded. Equal threshold decisions are deterministic and process as a
  simultaneous batch, matching the source's split operation.

The package oracle follows the source's maintained-degree update. The
independent verifier rebuilds degrees from each active induced graph. Workload
fixtures are in [`workload.json`](workload.json).

## Source and rights

Pinned source: GBBS commit
[`dbd1dcad582c0a316c5ba0d5524319d596dd82da`](https://github.com/ParAlg/gbbs/tree/dbd1dcad582c0a316c5ba0d5524319d596dd82da),
`benchmarks/ApproximateDensestSubgraph/ApproxPeelingBKV12/DensestSubgraph.h`
(`WorkEfficientDensestSubgraph`) and the corresponding `DensestSubgraph.cc`
launcher. GBBS is MIT licensed; the complete notice is in [`LICENSE.txt`](LICENSE.txt).
All language ports are clean-room implementations.

## Ports

| Language | Source |
| --- | --- |
| C | `c/g/gbbs_bkv12_densest_subgraph.c` |
| C3 | `c3/g/gbbs_bkv12_densest_subgraph.c3` |
| C++ | `cpp/g/gbbs_bkv12_densest_subgraph.cpp` |
| Elisa | `elisa/g/gbbs_bkv12_densest_subgraph.elisa` |
| Nim | `nim/g/gbbs_bkv12_densest_subgraph.nim` |
| Odin | `odin/g/gbbs_bkv12_densest_subgraph.odin` |
| Rust | `rust/g/gbbs_bkv12_densest_subgraph.rs` |
| V | `v/g/gbbs_bkv12_densest_subgraph.v` |
| Zig | `zig/g/gbbs_bkv12_densest_subgraph.zig` |

The independent verifier is [`gbbs_bkv12_densest_subgraph_verifier_oracle.py`](../../gbbs_bkv12_densest_subgraph_verifier_oracle.py).
