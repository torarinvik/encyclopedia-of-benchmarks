# KKT sampled-MSF heavy-edge filter

This bounded profile implements the filtering step described in “Randomized
Minimum Spanning Tree,” DOI
[`10.1007/978-1-4939-2864-4_325`](https://doi.org/10.1007/978-1-4939-2864-4_325).
The workload supplies one fixed sample mask. The profile computes the sampled
graph's minimum spanning forest `F`, then classifies every original edge using
the chapter's cycle-property definition of `F`-light and `F`-heavy edges.

Input is `[n,m,(u,v,weight,sampled)...]`, with `2 <= n <= 12`, `1 <= m <= 24`,
canonical endpoints `0 <= u < v < n`, simple undirected edges, unique positive
weights in `[1,1024]`, and sample bits in `{0,1}`. `F` is computed from the
sampled edges by deterministic Kruskal order. For an original edge `e`, output
byte 1 means it is `F`-light: it belongs to `F`, its endpoints are in different
components of `F`, or its weight is below the maximum edge weight on the unique
`F` path between its endpoints. Byte 0 means it is `F`-heavy. Unique weights
make the maximum-edge comparison unambiguous.

The result is one byte per original edge, at most 24 bytes. Invalid input
returns `-1`; null output or insufficient capacity returns `-2` without
writing. The profile covers one sampled-MSF filtering stage, not the full
recursive randomized KKT minimum-spanning-tree algorithm. It does not make a
runtime, success-probability, or linear-time claim.

| Language | Port |
|---|---|
| C | `c/k/kkt_mst_sampling_filter.c` |
| C3 | `c3/k/kkt_mst_sampling_filter.c3` |
| C++ | `cpp/k/kkt_mst_sampling_filter.cpp` |
| Elisa | `elisa/k/kkt_mst_sampling_filter.elisa` |
| Nim | `nim/k/kkt_mst_sampling_filter.nim` |
| Odin | `odin/k/kkt_mst_sampling_filter.odin` |
| Rust | `rust/k/kkt_mst_sampling_filter.rs` |
| V | `v/k/kkt_mst_sampling_filter.v` |
| Zig | `zig/k/kkt_mst_sampling_filter.zig` |
