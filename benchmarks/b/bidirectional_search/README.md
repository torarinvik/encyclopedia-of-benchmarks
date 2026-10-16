# Bidirectional search on an undirected graph

This package ports the pinned Python adjacency-list search to bounded, unweighted, undirected simple graphs. Vertices are integer IDs `0..n-1`; every vertex is explicit, each edge is encoded by exactly two reciprocal directed arcs, and input arc order preserves each vertex's neighbor order.

Input layout is `[vertex_count, start, goal, directed_arc_count, from0, to0, from1, to1, ...]`. The vertex count is 1 through 64, endpoints and arc endpoints must be in range, self-loops and duplicate directed arcs are invalid, and adjacency must be symmetric. Arc order determines per-vertex neighbor iteration order. Malformed inputs return `-1`.

The search alternates one FIFO node expansion from the start side and one from the goal side, always forward first. Within an expansion, it visits neighbors in their encoded order, skips already visited nodes, records the parent and enqueues before checking the other search's parent map, and stops at the first discovered intersection. On the undirected, unweighted domain, the first intersection yields a shortest path; adjacency order chooses deterministically among equal-length paths. If `start == goal`, the result is `[1, start]`; an unreachable goal produces `[0]`.

Output is a little-endian signed 64-bit vector `[path_count, vertex0, vertex1, ...]`. A null or undersized output buffer returns `-2`; success returns output bytes. With at most 64 vertices, the maximum output is 65 values (520 bytes).

## Pinned source

The canonical source is [TheAlgorithms/Python `bidirectional_search.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/bidirectional_search.py) at commit `e1a2a8b016001309a73d5fec4818c35cca139795`. It accepts adjacency dictionaries and returns a path list or `None`; this package supplies a bounded integer encoding and represents `None` as `[0]`.

## Implementations

The nine ports are located at the language's `b/` source path: `c/b/bidirectional_search.c`, `c3/b/bidirectional_search.c3`, `cpp/b/bidirectional_search.cpp`, `elisa/b/bidirectional_search.elisa`, `nim/b/bidirectional_search.nim`, `odin/b/bidirectional_search.odin`, `rust/b/bidirectional_search.rs`, `v/b/bidirectional_search.v`, and `zig/b/bidirectional_search.zig`.
