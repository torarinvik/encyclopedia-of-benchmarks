# Routing-cost constrained connected dominating set (GOC-MCDS-C)

This profile combines the centralized GOC-MCDS-C connector stage with the
published unique-ID MISI rule as a deterministic way to choose its maximal
independent set. In each synchronous MISI round, white vertices with the
smallest ID among their white neighbors turn black, and their white neighbors
turn gray. The connector stage considers every pair of MIS vertices at graph
distance at most four, finds a shortest path, and adds its intermediate
vertices to the connector set. A selected path can contribute up to three
internal vertices. The output contains both the MIS and the final connected
dominating set.

Input is `[n, adjacency_mask[n], node_id[n]]`, with `1<=n<=8`, symmetric
loop-free adjacency masks, a connected graph, and distinct IDs in `1..1000`.
For shortest-path ties, the profile chooses the lexicographically smallest
node-ID sequence; MIS pairs are considered in ascending ID order. Output is
`[independent_set_mask, connected_dominating_set_mask]` as two little-endian
i64 values. Malformed input returns `-1`; null output or capacity below 16
bytes returns `-2` without writing.

The chapter's approximation and routing-stretch guarantees are stated for
unit-disk graphs. This bounded graph-input profile does not validate a
geometric unit-disk representation and does not claim those guarantees. It
does not implement the chapter's distributed MIS-connection procedure
(Algorithm 3). The exact minimum weighted connected dominating set package
solves a different optimization problem.

## Distinction from local graph packages

[`weighted_connected_dominating_set`](../../w/weighted_connected_dominating_set/README.md)
enumerates the exact minimum-weight connected dominating set objective. It
does not use the GOC-MCDS-C MISI and distance-four connector construction.
[`domination_local_reduction`](../../d/domination_local_reduction/README.md)
applies local reductions and does not construct a connected dominating set.
[`two_edge_connected_spanning_subgraph_greedy`](../../t/two_edge_connected_spanning_subgraph_greedy/README.md)
augments edge connectivity, while
[`geometric_greedy_compass_routing`](../../g/geometric_greedy_compass_routing/README.md)
performs per-packet forwarding; neither builds a routing-cost constrained
dominating backbone.

The chapter cites the primary GOC-MCDS work. Its §III gives the centralized
distance-four connector stage; §IV specifies the unique-ID MISI rounds used
here as the deterministic MIS selector. Source: “Routing-Cost Constrained
Connected Dominating Set,” *Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_621`](https://doi.org/10.1007/978-1-4939-2864-4_621);
H. Du et al., “CDS-based virtual backbone construction with guaranteed routing
Cost in Wireless Sensor Networks,” *IEEE Transactions on Parallel and
Distributed Systems* 24(4), 652–661 (2013), DOI
[`10.1109/TPDS.2012.177`](https://doi.org/10.1109/TPDS.2012.177), §§III–IV.
See [RIGHTS.md](RIGHTS.md) for attribution.

The primary oracle simulates the synchronous local-minimum MIS rounds and
uses lexicographic BFS. The independent verifier constructs the MIS in
ascending-ID greedy order and resolves shortest-path ties from an all-pairs
distance matrix. The [workload](workload.json) includes a path with an MIS pair
at distance four, plus singleton, tie-resolved cycle, maximum-size clique,
malformed graph/IDs, and output-capacity cases. The package-local
[`verify_workload.py`](verify_workload.py) checks metadata and static paths;
it is not part of the benchmark call.

| Language | Port |
|---|---|
| C | `c/r/routing_cost_constrained_cds_goc_mcds_c.c` |
| C3 | `c3/r/routing_cost_constrained_cds_goc_mcds_c.c3` |
| C++ | `cpp/r/routing_cost_constrained_cds_goc_mcds_c.cpp` |
| Elisa | `elisa/r/routing_cost_constrained_cds_goc_mcds_c.elisa` |
| Mojo | `mojo/r/routing_cost_constrained_cds_goc_mcds_c.mojo` |
| Nim | `nim/r/routing_cost_constrained_cds_goc_mcds_c.nim` |
| Odin | `odin/r/routing_cost_constrained_cds_goc_mcds_c.odin` |
| Rust | `rust/r/routing_cost_constrained_cds_goc_mcds_c.rs` |
| V | `v/r/routing_cost_constrained_cds_goc_mcds_c.v` |
| Zig | `zig/r/routing_cost_constrained_cds_goc_mcds_c.zig` |
