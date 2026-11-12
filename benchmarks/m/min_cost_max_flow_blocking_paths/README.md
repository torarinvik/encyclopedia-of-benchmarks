# Minimum-cost maximum flow with tight-edge blocking flow

This package provides a method comparison for the existing bounded
`min_cost_max_flow` contract. Each shortest-distance phase is followed by a
maximum-flow computation in the tight residual subgraph, where every usable arc
satisfies `dist[v] = dist[u] + cost`. The tight subgraph is handled with layered
BFS and blocking-flow DFS. Sending any source-to-sink path in that subgraph has
the same shortest residual cost, so the phase can move multiple path units
before distances are recomputed.

The local `min_cost_max_flow` package uses reduced-cost Dijkstra and augments one
bottleneck path per phase. `minimum_cost_b_flow` instead finds a feasible
circulation adjustment and cancels negative residual cycles. These contracts
and methods remain separately represented.

## Contract

The exported `min_cost_max_flow_blocking_paths` entry point uses the
`i64_array_bytes_output` ABI. Input is a signed-i64 array:

`[vertex_count, edge_count, source, sink, flow_limit, (from, to, capacity, cost)*edge_count]`

Vertices are zero-based. The directed multigraph accepts parallel edges and
self-loops. Bounds are `2<=vertex_count<=8`, `0<=edge_count<=16`,
`0<=flow_limit<=16`, `0<=capacity<=5`, and `0<=cost<=20`. Original forward
costs are nonnegative; reverse residual arcs receive the negated cost.

The result is exactly 16 bytes: achieved flow as little-endian signed i64,
followed by minimum total cost in the same encoding. The method augments until
the requested flow limit is reached or no residual source-to-sink path remains.
Malformed input returns `-1`. A null output or capacity below 16 bytes returns
`-2` without writes.

The primary oracle uses shortest-distance labels and tight-subgraph blocking
flow. An independent oracle uses Bellman–Ford successive shortest paths. The
workload reuses the existing contract's multiple-path, flow-limit,
residual-rerouting, disconnected, zero-limit, and malformed-frame cases; suite
integration can add generated maximum, null-buffer, and capacity probes.

## Provenance and rights

The method distinction was identified from the high-level Dinic-like section of
[OI Wiki's minimum-cost flow article](https://en.oi-wiki.org/graph/flow/min-cost/).
The page is marked CC BY-SA 4.0 and SATA. Ports and oracle are clean-room
implementations based on the algorithm description; no article code or prose
was copied. See [`RIGHTS.md`](RIGHTS.md).

## Ports

| Language | Port |
|---|---|
| C | [`c/m/min_cost_max_flow_blocking_paths.c`](../../../c/m/min_cost_max_flow_blocking_paths.c) |
| C3 | [`c3/m/min_cost_max_flow_blocking_paths.c3`](../../../c3/m/min_cost_max_flow_blocking_paths.c3) |
| C++ | [`cpp/m/min_cost_max_flow_blocking_paths.cpp`](../../../cpp/m/min_cost_max_flow_blocking_paths.cpp) |
| Elisa | [`elisa/m/min_cost_max_flow_blocking_paths.elisa`](../../../elisa/m/min_cost_max_flow_blocking_paths.elisa) |
| Mojo | [`mojo/m/min_cost_max_flow_blocking_paths.mojo`](../../../mojo/m/min_cost_max_flow_blocking_paths.mojo) |
| Nim | [`nim/m/min_cost_max_flow_blocking_paths.nim`](../../../nim/m/min_cost_max_flow_blocking_paths.nim) |
| Odin | [`odin/m/min_cost_max_flow_blocking_paths.odin`](../../../odin/m/min_cost_max_flow_blocking_paths.odin) |
| Rust | [`rust/m/min_cost_max_flow_blocking_paths.rs`](../../../rust/m/min_cost_max_flow_blocking_paths.rs) |
| V | [`v/m/min_cost_max_flow_blocking_paths.v`](../../../v/m/min_cost_max_flow_blocking_paths.v) |
| Zig | [`zig/m/min_cost_max_flow_blocking_paths.zig`](../../../zig/m/min_cost_max_flow_blocking_paths.zig) |
