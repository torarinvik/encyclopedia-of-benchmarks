# Lua directed weighted graph trace

This package models a bounded operation trace against the pinned Lua graph object. The input creates a fixed set of integer nodes, then exercises directed edge updates, removals, weight queries, and edge-existence queries.

## Contract

- Input is `[node_count, operation_count, (operation,from,to,value)...]` as signed 64-bit integers, with exact packing and no trailing fields. Nodes `0..node_count-1` are created before the trace. There are 1 through 16 nodes and 0 through 63 fixed-width operations.
- Operation `0` sets a numeric edge weight in `[-1000,1000]`, replacing any previous weight. Operation `1` sets a boolean `true` weight. Operation `2` removes an edge and succeeds when it is already absent. Operation `3` adds an unweighted edge represented by `true`; adding an existing edge is invalid, as in the source assertion. Operations `4` and `5` query weight and edge presence. For operations other than `0`, the final field must be zero.
- The graph is directed. Self-edges are allowed, and each ordered pair has at most one current edge. `true` and numeric weight `1` remain distinct values.
- Output is a little-endian signed i64 vector:
  `[operation_count, (result_kind,result_value)*operation_count, final_edge_count, sorted (from,to,weight_kind,weight_value) edges...]`.
  Mutation result kind is `-1`; `get_weight` reports absent as `(0,0)`, boolean true as `(1,0)`, and numeric weights as `(2,weight)`. `has_edge` reports `(0,0)` or `(1,0)`. Final edges sort by source ID then destination ID, making the result deterministic despite Lua's unspecified `pairs` iteration order. The function returns the output byte count.
- Malformed traces or out-of-domain fields return `-1`; insufficient capacity or a null output buffer returns `-2`.

This contract covers the graph's directed weighted storage and its `set_weight`, `add_edge`, `remove_edge`, `get_weight`, and `has_edge` behavior. The wider Lua module also contains traversal, shortest-path, cycle, component, and flow algorithms; those are outside this package's operation trace.

## Pinned source

- [TheAlgorithms/Lua `graph.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/data_structures/graph.lua)

[`workload.json`](workload.json) covers numeric overwrite, deletion, absent queries, boolean weights, zero and negative weights, self-edges, empty traces, and invalid duplicate additions and fields.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/g/graph_lua_directed_weighted.c`](../../../c/g/graph_lua_directed_weighted.c) |
| C3 | [`c3/g/graph_lua_directed_weighted.c3`](../../../c3/g/graph_lua_directed_weighted.c3) |
| C++ | [`cpp/g/graph_lua_directed_weighted.cpp`](../../../cpp/g/graph_lua_directed_weighted.cpp) |
| Elisa | [`elisa/g/graph_lua_directed_weighted.elisa`](../../../elisa/g/graph_lua_directed_weighted.elisa) |
| Nim | [`nim/g/graph_lua_directed_weighted.nim`](../../../nim/g/graph_lua_directed_weighted.nim) |
| Odin | [`odin/g/graph_lua_directed_weighted.odin`](../../../odin/g/graph_lua_directed_weighted.odin) |
| Rust | [`rust/g/graph_lua_directed_weighted.rs`](../../../rust/g/graph_lua_directed_weighted.rs) |
| V | [`v/g/graph_lua_directed_weighted.v`](../../../v/g/graph_lua_directed_weighted.v) |
| Zig | [`zig/g/graph_lua_directed_weighted.zig`](../../../zig/g/graph_lua_directed_weighted.zig) |
