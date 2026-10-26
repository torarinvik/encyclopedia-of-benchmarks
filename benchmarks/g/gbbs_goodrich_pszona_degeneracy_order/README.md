# GBBS Goodrich–Pszona degeneracy order

This package is a bounded deterministic projection of GBBS
`DegeneracyOrder_intsort` from `benchmarks/DegeneracyOrder/GoodrichPszona11/DegeneracyOrder.h`,
pinned at commit `dbd1dcad582c0a316c5ba0d5524319d596dd82da`.

This bounded profile uses the pinned source default `epsilon=0.001`. For
`1 <= n <= 20`, `ns=ceil(n*epsilon/(2+epsilon))` clamped to at least one is
always one. The
source therefore sorts the remaining vertices by current induced degree,
removes one minimum-degree vertex, and decreases the current degree of each
remaining neighbor. The profile breaks equal-degree ties by lowest vertex ID
to make the source's sorting tie behavior deterministic. It returns the inverse
permutation: output element `v` is the rank of vertex `v` in the removal order.

## Contract

- Exported symbol: `gbbs_goodrich_pszona_degeneracy_order`.
- ABI: `i64_array_bytes_output`.
- Input: `[node_count, edge_count, (u, v)...]`, with each undirected edge
  listed once and `u < v`.
- Bounds: `1 <= node_count <= 20`, `0 <= edge_count <= 190`, and exact input
  length `2 + 2*edge_count`. Self-loops, duplicate edges, and noncanonical
  endpoints are invalid.
- Output: one little-endian signed 64-bit rank per vertex, ordered by vertex
  ID. Success returns `8*node_count` bytes. Malformed input returns `-1`;
  null output or insufficient capacity returns `-2` without writing.
- The sequential degree selection is source-shaped for the fixed `ns=1`
  profile. Graph loading, parallel integer sorting, edge-map scheduling,
  timing, and launcher output are excluded.

The package oracle uses sorted active-degree keys. The independent verifier
uses repeated minimum scans. Both apply the documented vertex-ID tie rule.
Fixtures are in [`workload.json`](workload.json).

## Source and rights

Source: [`DegeneracyOrder.h::DegeneracyOrder_intsort`](https://github.com/ParAlg/gbbs/blob/dbd1dcad582c0a316c5ba0d5524319d596dd82da/benchmarks/DegeneracyOrder/GoodrichPszona11/DegeneracyOrder.h).
GBBS is MIT licensed; the full notice is in [`LICENSE.txt`](LICENSE.txt).
Ports are clean-room implementations.

## Ports

| Language | Source |
| --- | --- |
| C | [`c/g/gbbs_goodrich_pszona_degeneracy_order.c`](../../../c/g/gbbs_goodrich_pszona_degeneracy_order.c) |
| C3 | [`c3/g/gbbs_goodrich_pszona_degeneracy_order.c3`](../../../c3/g/gbbs_goodrich_pszona_degeneracy_order.c3) |
| C++ | [`cpp/g/gbbs_goodrich_pszona_degeneracy_order.cpp`](../../../cpp/g/gbbs_goodrich_pszona_degeneracy_order.cpp) |
| Elisa | [`elisa/g/gbbs_goodrich_pszona_degeneracy_order.elisa`](../../../elisa/g/gbbs_goodrich_pszona_degeneracy_order.elisa) |
| Nim | [`nim/g/gbbs_goodrich_pszona_degeneracy_order.nim`](../../../nim/g/gbbs_goodrich_pszona_degeneracy_order.nim) |
| Odin | [`odin/g/gbbs_goodrich_pszona_degeneracy_order.odin`](../../../odin/g/gbbs_goodrich_pszona_degeneracy_order.odin) |
| Rust | [`rust/g/gbbs_goodrich_pszona_degeneracy_order.rs`](../../../rust/g/gbbs_goodrich_pszona_degeneracy_order.rs) |
| V | [`v/g/gbbs_goodrich_pszona_degeneracy_order.v`](../../../v/g/gbbs_goodrich_pszona_degeneracy_order.v) |
| Zig | [`zig/g/gbbs_goodrich_pszona_degeneracy_order.zig`](../../../zig/g/gbbs_goodrich_pszona_degeneracy_order.zig) |

Package oracle: [`gbbs_goodrich_pszona_degeneracy_order_oracle.py`](../../gbbs_goodrich_pszona_degeneracy_order_oracle.py).
Independent verifier model: [`gbbs_goodrich_pszona_degeneracy_order_verifier_oracle.py`](../../gbbs_goodrich_pszona_degeneracy_order_verifier_oracle.py).
