# Bidirectional Dijkstra

This package returns the shortest distance from a source vertex to a target vertex in a directed graph with nonnegative edge weights. The bounded input layout is `[vertex_count, edge_count, source, target, (from, to, weight)...]`, with zero-based vertex IDs. The graph may contain parallel edges and self-loops.

The contract accepts 1 through 64 vertices, 0 through 256 edges, and weights from 0 through 1,000,000. The input must contain exactly `4 + 3 * edge_count` values. A valid query returns its shortest distance, `-1` when the target is unreachable, and `-1` for malformed input. The largest possible shortest distance is 63,000,000.

The ports alternate between forward and reverse Dijkstra frontiers, scanning the bounded edge list and selecting each frontier's minimum unsettled distance. They update the best complete route at shared vertices and crossing edges, and stop when the two frontier minima cannot improve that route. This preserves the shortest-distance contract while keeping the implementation bounded and deterministic.

| Language | Port |
|---|---|
| C | [`c/b/bidirectional_dijkstra.c`](../../../c/b/bidirectional_dijkstra.c) |
| C3 | [`c3/b/bidirectional_dijkstra.c3`](../../../c3/b/bidirectional_dijkstra.c3) |
| C++ | [`cpp/b/bidirectional_dijkstra.cpp`](../../../cpp/b/bidirectional_dijkstra.cpp) |
| Elisa | [`elisa/b/bidirectional_dijkstra.elisa`](../../../elisa/b/bidirectional_dijkstra.elisa) |
| Nim | [`nim/b/bidirectional_dijkstra.nim`](../../../nim/b/bidirectional_dijkstra.nim) |
| Odin | [`odin/b/bidirectional_dijkstra.odin`](../../../odin/b/bidirectional_dijkstra.odin) |
| Rust | [`rust/b/bidirectional_dijkstra.rs`](../../../rust/b/bidirectional_dijkstra.rs) |
| V | [`v/b/bidirectional_dijkstra.v`](../../../v/b/bidirectional_dijkstra.v) |
| Zig | [`zig/b/bidirectional_dijkstra.zig`](../../../zig/b/bidirectional_dijkstra.zig) |

The two pinned C++ candidate files are [C-Plus-Plus at `fdcc29b0`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/graph/bidirectional_dijkstra.cpp) and [C-Plus-Plus-1 at `0f20cdcf`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/graph/bidirectional_dijkstra.cpp). They implement the same directed, nonnegative-weight search; their only source difference is that the first file explicitly includes `<cstdint>`. The pinned examples, command-line input, timing code, and `int` return truncation are excluded from this bounded distance contract. See [`workload.json`](workload.json) for representative and malformed cases.
