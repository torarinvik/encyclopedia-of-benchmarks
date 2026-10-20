# Minimum-cost maximum flow

This package implements the min-cost max-flow operation represented by
AtCoder Library's `mcf_graph::flow`. It uses successive shortest augmenting
paths with reduced-cost potentials and a bounded array-based Dijkstra search.
An independent Bellman-Ford oracle checks the flow and cost results.

The implementation is a new bounded port, not a copied translation of the
AtCoder C++ source. AtCoder's source and license are pinned and attributed
below; the source is CC0 1.0 Universal. The complete upstream notice is bundled
in [`LICENSE.txt`](LICENSE.txt).

## Contract

The exported `min_cost_max_flow` entry point uses the
`i64_array_bytes_output` ABI. Input is a signed-i64 array:

`[vertex_count, edge_count, source, sink, flow_limit, (from, to, capacity, cost)*]`

Vertices are zero-based. The graph is directed; parallel edges and self-loops
are accepted. `vertex_count` is 2 through 8, `edge_count` is 0 through 16,
`flow_limit` is 0 through 16, capacities are 0 through 5, and forward edge
costs are nonnegative values from 0 through 20. Nonnegative initial costs
match the supported input domain of the pinned AtCoder API. Residual reverse
edges carry the negated cost internally.

The algorithm returns the maximum flow from source to sink up to the requested
limit and the minimum total cost for that flow. If no route exists, both
results are zero. Output is exactly 16 bytes: total flow as little-endian
signed i64, followed by total cost in the same encoding. Invalid input returns
`-1` before output checks. Null output or capacity below 16 bytes returns `-2`
without writing. Success returns `16`.

The workload includes multiple paths, a flow limit, residual rerouting, no
route, zero flow, and malformed/boundary cases. [`workload.json`](workload.json)
contains fixture outputs. The independent
[`min_cost_max_flow_oracle.py`](../../min_cost_max_flow_oracle.py) uses
Bellman-Ford over residual edges rather than the ports' reduced-cost Dijkstra.

## Pinned source and attribution

- [AtCoder `mincostflow.hpp`](https://github.com/atcoder/ac-library/blob/864245a00b00dd008d1abfdc239618fdb7d139da/atcoder/mincostflow.hpp), pinned at commit `864245a00b00dd008d1abfdc239618fdb7d139da`, provides `mcf_graph::flow(s, t, flow_limit)` and its successive shortest path/potential semantics.
- [AtCoder min-cost flow documentation](https://github.com/atcoder/ac-library/blob/864245a00b00dd008d1abfdc239618fdb7d139da/document_en/mincostflow.md) identifies the min-cost flow component and states that library files are CC0.
- [`LICENSE.txt`](LICENSE.txt) is the complete CC0 1.0 Universal notice from the pinned repository.

## Ports

| Language | Port |
|---|---|
| C | [`c/m/min_cost_max_flow.c`](../../../c/m/min_cost_max_flow.c) |
| C3 | [`c3/m/min_cost_max_flow.c3`](../../../c3/m/min_cost_max_flow.c3) |
| C++ | [`cpp/m/min_cost_max_flow.cpp`](../../../cpp/m/min_cost_max_flow.cpp) |
| Elisa | [`elisa/m/min_cost_max_flow.elisa`](../../../elisa/m/min_cost_max_flow.elisa) |
| Nim | [`nim/m/min_cost_max_flow.nim`](../../../nim/m/min_cost_max_flow.nim) |
| Odin | [`odin/m/min_cost_max_flow.odin`](../../../odin/m/min_cost_max_flow.odin) |
| Rust | [`rust/m/min_cost_max_flow.rs`](../../../rust/m/min_cost_max_flow.rs) |
| V | [`v/m/min_cost_max_flow.v`](../../../v/m/min_cost_max_flow.v) |
| Zig | [`zig/m/min_cost_max_flow.zig`](../../../zig/m/min_cost_max_flow.zig) |
