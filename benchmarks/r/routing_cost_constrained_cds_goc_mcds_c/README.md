# Routing-cost constrained connected dominating set (GOC-MCDS-C)

This profile implements the chapter's centralized two-stage GOC-MCDS-C
construction on a supplied small connected undirected graph. Stage 1 uses the
chapter's unique-ID MISI rule: in each synchronous round, white vertices that
have the smallest ID among their white neighbors turn black, and their white
neighbors turn gray. Stage 2 considers every pair of MIS vertices at graph
distance at most three, finds a shortest path, and adds its intermediate
vertices to the connector set. The output contains both the MIS and the final
connected dominating set.

Input is `[n, adjacency_mask[n], node_id[n]]`, with `1<=n<=8`, symmetric
loop-free adjacency masks, a connected graph, and distinct IDs in `1..1000`.
For shortest-path ties, the profile orders candidate paths lexicographically
by node ID; MIS pairs are considered in ascending ID order. Output is
`[independent_set_mask, connected_dominating_set_mask]` as two little-endian
i64 values. Malformed input returns `-1`; null output or capacity below 16
bytes returns `-2` without writing.

The chapter's approximation and routing-stretch guarantees are stated for
unit-disk graphs. This bounded graph-input profile does not validate a
geometric unit-disk representation and does not claim those guarantees. It
does not implement the chapter's distributed MIS-connection procedure
(Algorithm 3). The exact minimum weighted connected dominating set package
solves a different optimization problem.

Source: “Routing-Cost Constrained Connected Dominating Set,” *Encyclopedia of
Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_621`](https://doi.org/10.1007/978-1-4939-2864-4_621).
See [RIGHTS.md](RIGHTS.md) for attribution.

The primary oracle simulates the synchronous local-minimum MIS rounds and
uses lexicographic BFS. The independent verifier constructs the MIS in
ascending-ID greedy order and resolves shortest-path ties from an all-pairs
distance matrix. The [workload](workload.json) covers singleton, path,
tie-resolved cycle, maximum-size clique, malformed graph/IDs, and output
capacity cases.

| Language | Port |
|---|---|
| C | `c/r/routing_cost_constrained_cds_goc_mcds_c.c` |
| C3 | `c3/r/routing_cost_constrained_cds_goc_mcds_c.c3` |
| C++ | `cpp/r/routing_cost_constrained_cds_goc_mcds_c.cpp` |
| Elisa | `elisa/r/routing_cost_constrained_cds_goc_mcds_c.elisa` |
| Nim | `nim/r/routing_cost_constrained_cds_goc_mcds_c.nim` |
| Odin | `odin/r/routing_cost_constrained_cds_goc_mcds_c.odin` |
| Rust | `rust/r/routing_cost_constrained_cds_goc_mcds_c.rs` |
| V | `v/r/routing_cost_constrained_cds_goc_mcds_c.v` |
| Zig | `zig/r/routing_cost_constrained_cds_goc_mcds_c.zig` |
