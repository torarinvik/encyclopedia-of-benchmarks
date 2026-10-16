# Depth-first search target route

This benchmark follows the Go `DepthFirstSearch` function. It searches an undirected graph with an explicit stack and returns the order in which nodes are popped, stopping when the target is popped. That sequence is a traversal route; it need not be a simple path.

## Contract

- Pack `[node_count, start_label, target_label, node_label_0, ..., node_label_(node_count-1), edge_count, left_0, right_0, ...]` into the signed 64-bit array ABI.
- `node_count` is 1 through 64. Node labels and the target label are bytes in 0 through 255. Node labels must be unique, and the start label must be present. An absent target is valid and is unreachable.
- `edge_count` is 0 through 94. Each edge endpoint must be a listed node label. Every edge adds both adjacency directions. Duplicate edges coalesce, matching the source's Boolean matrix; self-loops are allowed.
- The node-label list controls neighbor scan order. Each popped node scans its neighbors in list order, pushes them onto a LIFO stack, and clears each traversed edge in both directions. Later neighbors in the list are therefore popped first.
- The result is the number of bytes in the returned route. Each byte is a node label. If the target is unreachable, the result is 0 and the output is empty. Malformed input or insufficient output capacity returns `-2` without writing output.
- The packed input limit is 256 values, derived from 64 labels and 94 edges. The output workspace is bounded to 128 bytes. A source self-loop is pushed once before the edge is cleared, so a route can contain a node twice.

The pinned Go implementation accepts a node list and a Boolean adjacency matrix. The packed edge-list ABI reconstructs that matrix at the entry point, so validation and matrix construction are included in the timed call. `DepthFirstSearch` calls its helper with `showroute == false`; it returns the route only after popping the target, while an unsuccessful search returns `nil, false`. The workload includes both pinned examples, absent and unreachable targets, stack ordering, duplicate edges, self-loops, and maximum-size input. Expected route bytes are listed as hex in [`workload.json`](workload.json). The independent oracle is [`depth_first_search_target_route_oracle.py`](../../depth_first_search_target_route_oracle.py).

## Source

- [TheAlgorithms/Go `depthfirstsearch.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/graph/depthfirstsearch.go), commit `5ba447ec5ff3d1213de65b92e726ee74c5d5cc19`.

Build and record with the `i64_array_bytes_output` ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm depth_first_search_target_route --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/d/depth_first_search_target_route/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm depth_first_search_target_route
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/d/depth_first_search_target_route.c`](../../../c/d/depth_first_search_target_route.c) |
| C3 | [`c3/d/depth_first_search_target_route.c3`](../../../c3/d/depth_first_search_target_route.c3) |
| C++ | [`cpp/d/depth_first_search_target_route.cpp`](../../../cpp/d/depth_first_search_target_route.cpp) |
| Elisa | [`elisa/d/depth_first_search_target_route.elisa`](../../../elisa/d/depth_first_search_target_route.elisa) |
| Nim | [`nim/d/depth_first_search_target_route.nim`](../../../nim/d/depth_first_search_target_route.nim) |
| Odin | [`odin/d/depth_first_search_target_route.odin`](../../../odin/d/depth_first_search_target_route.odin) |
| Rust | [`rust/d/depth_first_search_target_route.rs`](../../../rust/d/depth_first_search_target_route.rs) |
| V | [`v/d/depth_first_search_target_route.v`](../../../v/d/depth_first_search_target_route.v) |
| Zig | [`zig/d/depth_first_search_target_route.zig`](../../../zig/d/depth_first_search_target_route.zig) |
