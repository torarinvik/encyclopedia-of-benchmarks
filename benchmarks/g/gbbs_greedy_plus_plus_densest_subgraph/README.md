# GBBS GreedyPlusPlus approximate densest subgraph

This package profiles GBBS `GreedyPlusPlusDensestSubgraph`. The source starts
with graph degrees as a load vector and performs 20 iterations. Each iteration
computes a degeneracy ordering under the current load, adds each vertex's
number of later neighbors to its load, and measures the average degree of every
induced suffix. The result is the maximum score across all suffixes and rounds.

This is distinct from local
[`gbbs_charikar_densest_subgraph`](../gbbs_charikar_densest_subgraph/README.md),
which uses one unweighted minimum-degree ordering, and from
[`gbbs_bkv12_densest_subgraph`](../gbbs_bkv12_densest_subgraph/README.md),
which removes threshold-selected batches. GreedyPlusPlus's persistent load
updates change later orders and are part of its algorithm.

## Contract

- Exported symbol: `gbbs_greedy_plus_plus_densest_subgraph`; ABI:
  `i64_array_float64`.
- Input: `[node_count, edge_count, (u, v)...]`; simple undirected edges appear
  once with `u < v`.
- Bounds: `10 <= node_count <= 16`, `0 <= edge_count <= 64`, exact length
  `2 + 2*edge_count`. The lower bound follows the pinned source launcher body,
  which prints the first ten load values.
- Output: binary64 maximum average-degree score across exactly 20 rounds;
  malformed input returns `-1e300`.
- The bounded profile replaces the source bucket data structure with exact
  deterministic minimum-load shells, preserving the degree decrement and
  `max(load - removed_neighbors, shell_level)` update. Ties are ordered by
  ascending vertex ID. Each round computes `2 * later_neighbors`, adds its
  half to the vertex load, reverse-scans the doubled counts, and scores every
  suffix.
- Symmetric graph loading, bucket scheduling, diagnostics and timing are
  excluded. Scores remain the source's average degree (`2E/V`).

The package oracle follows the source load vector and shell updates; the
independent verifier rebuilds active residual loads and scans the ordered edge
list. See [`workload.json`](workload.json) for fixtures.

## Source and rights

Pinned GBBS commit
[`dbd1dcad582c0a316c5ba0d5524319d596dd82da`](https://github.com/ParAlg/gbbs/tree/dbd1dcad582c0a316c5ba0d5524319d596dd82da):
`benchmarks/ApproximateDensestSubgraph/GreedyPlusPlus/DensestSubgraph.h`
(`GreedyPlusPlusDensestSubgraph`) and
`benchmarks/KCore/JulienneDBS17/KCore.h` (`DegeneracyOrderWithLoad`). GBBS is
MIT licensed; the complete notice is in [`LICENSE.txt`](LICENSE.txt). All
ports are clean-room implementations.

## Ports

| Language | Source |
| --- | --- |
| C | `c/g/gbbs_greedy_plus_plus_densest_subgraph.c` |
| C3 | `c3/g/gbbs_greedy_plus_plus_densest_subgraph.c3` |
| C++ | `cpp/g/gbbs_greedy_plus_plus_densest_subgraph.cpp` |
| Elisa | `elisa/g/gbbs_greedy_plus_plus_densest_subgraph.elisa` |
| Nim | `nim/g/gbbs_greedy_plus_plus_densest_subgraph.nim` |
| Odin | `odin/g/gbbs_greedy_plus_plus_densest_subgraph.odin` |
| Rust | `rust/g/gbbs_greedy_plus_plus_densest_subgraph.rs` |
| V | `v/g/gbbs_greedy_plus_plus_densest_subgraph.v` |
| Zig | `zig/g/gbbs_greedy_plus_plus_densest_subgraph.zig` |

Independent verifier: [`gbbs_greedy_plus_plus_densest_subgraph_verifier_oracle.py`](../../gbbs_greedy_plus_plus_densest_subgraph_verifier_oracle.py).
