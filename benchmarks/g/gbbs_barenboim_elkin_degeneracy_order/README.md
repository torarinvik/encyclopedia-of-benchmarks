# GBBS Barenboim–Elkin degeneracy order

This package profiles GBBS `barenboimelkin_degen::DegeneracyOrder`. The
launcher default is `epsilon=0.1`; it estimates `alpha` with the BKV12
work-efficient densest-subgraph routine, then sets
`cutoff=max(ceil(alpha*epsilon), 1)`. Each ordering round removes every
remaining vertex whose current degree is below that cutoff. If the low-degree
batch is empty, the source forces one removal. It decrements surviving
neighbors' degrees and returns inverse removal ranks.

This is distinct from the local
[`gbbs_goodrich_pszona_degeneracy_order`](../gbbs_goodrich_pszona_degeneracy_order/README.md)
profile, which removes minimum-degree vertices one at a time under its pinned
`DegeneracyOrder_intsort` projection. Barenboim–Elkin uses a BKV12 density
estimate to choose a degree threshold and may peel a wider low-degree batch;
when the batch is empty, it removes the first remaining item rather than the
minimum-degree vertex. The package refines source ordering ties with ascending
vertex ID.

## Contract

- Exported symbol: `gbbs_barenboim_elkin_degeneracy_order`; ABI:
  `i64_array_bytes_output`.
- Input: `[node_count, edge_count, (u, v)...]`; simple undirected edges appear
  once with `u < v`.
- Bounds: `1 <= node_count <= 20`, `0 <= edge_count <= 190`, exact length
  `2 + 2*edge_count`.
- Output: one little-endian signed 64-bit removal rank per vertex in vertex-ID
  order. Success returns `8*node_count` bytes; malformed input returns `-1`;
  null output or insufficient capacity returns `-2` without writing.
- The BKV density estimate uses the outer launcher epsilon `0.1` in both the
  `(1+epsilon)` threshold-peeling pass and the cutoff calculation. Exact
  rational comparisons represent the decimal constants and avoid cross-port
  floating decisions.
- Parallel integer sorting, bucket scheduling, graph loading, timing, and
  launcher output are excluded. The deterministic profile uses ascending IDs
  within low-degree batches and chooses the lowest remaining ID for the
  source's forced single-removal case.

The primary oracle maintains BKV and residual-order degrees. The independent
verifier rebuilds induced degrees from active edge sets. See
[`workload.json`](workload.json) for fixtures.

## Source and rights

Pinned GBBS commit
[`dbd1dcad582c0a316c5ba0d5524319d596dd82da`](https://github.com/ParAlg/gbbs/tree/dbd1dcad582c0a316c5ba0d5524319d596dd82da):
`benchmarks/DegeneracyOrder/BarenboimElkin08/DegeneracyOrder.h` and its
launcher, plus
`benchmarks/ApproximateDensestSubgraph/ApproxPeelingBKV12/DensestSubgraph.h`
(`WorkEfficientDensestSubgraph`). GBBS is MIT licensed; the complete notice
is in [`LICENSE.txt`](LICENSE.txt). All ports are clean-room implementations.

## Ports

| Language | Source |
| --- | --- |
| C | `c/g/gbbs_barenboim_elkin_degeneracy_order.c` |
| C3 | `c3/g/gbbs_barenboim_elkin_degeneracy_order.c3` |
| C++ | `cpp/g/gbbs_barenboim_elkin_degeneracy_order.cpp` |
| Elisa | `elisa/g/gbbs_barenboim_elkin_degeneracy_order.elisa` |
| Nim | `nim/g/gbbs_barenboim_elkin_degeneracy_order.nim` |
| Odin | `odin/g/gbbs_barenboim_elkin_degeneracy_order.odin` |
| Rust | `rust/g/gbbs_barenboim_elkin_degeneracy_order.rs` |
| V | `v/g/gbbs_barenboim_elkin_degeneracy_order.v` |
| Zig | `zig/g/gbbs_barenboim_elkin_degeneracy_order.zig` |

Independent verifier: [`gbbs_barenboim_elkin_degeneracy_order_verifier_oracle.py`](../../gbbs_barenboim_elkin_degeneracy_order_verifier_oracle.py).
