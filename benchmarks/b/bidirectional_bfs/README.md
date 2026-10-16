# Bidirectional BFS path

This package ports the `bidirectional_bfs` function from the pinned TheAlgorithms R source. It searches a bounded undirected, unweighted graph and returns a vertex path.

Input is `[vertex_count, start, target, arc_count, (from, to)...]`. The graph has 1 through 64 explicit vertices with IDs `0..vertex_count-1`, and at most 4096 directed arc records. Every endpoint must be in range. Adjacency must be symmetric by edge presence; duplicate arc records and self-loops are allowed. Repeated neighbors have no effect after the first occurrence, as the source marks vertices visited before later duplicates are considered. For each vertex, the first occurrence order of its outgoing arcs is retained and determines parent ties.

The search expands one complete FIFO level from the source, checks for intersections, then expands one complete level from the target and checks again. At each check, common visited vertices are scanned by ascending vertex ID and the first is selected. Parent ties within a level follow the encoded adjacency order. Equal endpoints return `[1, start]`; unreachable endpoints return `[0]`.

Output is `[path_count, vertex0, vertex1, ...]` encoded as little-endian signed 64-bit values. The count includes both endpoints. A nonempty path also carries the source result's distance as `path_count - 1` and found status as `path_count > 0`; an empty path represents source `path = NULL`, `distance = Inf`, `found = FALSE`. Malformed input returns `-1`; null or insufficient output capacity returns `-2`; success returns the output byte length. The maximum output is 65 values (520 bytes).

## Pinned source and extraction note

Pinned source: [TheAlgorithms/R `bidirectional_bfs.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/graph_algorithms/bidirectional_bfs.r) at commit `f65344fabeea0ae33c1ca321af709447c1a8a4c2`.

The function definition at lines 24–109 is self-contained and benchmarkable. The pinned file then ends with an unrelated top-level `return(list(...))` fragment at lines 143–147, which makes sourcing the complete file fail after the function has been defined. The ports implement the function definition and exclude that invalid trailing fragment.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/bidirectional_bfs.c`](../../../c/b/bidirectional_bfs.c) |
| C3 | [`c3/b/bidirectional_bfs.c3`](../../../c3/b/bidirectional_bfs.c3) |
| C++ | [`cpp/b/bidirectional_bfs.cpp`](../../../cpp/b/bidirectional_bfs.cpp) |
| Elisa | [`elisa/b/bidirectional_bfs.elisa`](../../../elisa/b/bidirectional_bfs.elisa) |
| Nim | [`nim/b/bidirectional_bfs.nim`](../../../nim/b/bidirectional_bfs.nim) |
| Odin | [`odin/b/bidirectional_bfs.odin`](../../../odin/b/bidirectional_bfs.odin) |
| Rust | [`rust/b/bidirectional_bfs.rs`](../../../rust/b/bidirectional_bfs.rs) |
| V | [`v/b/bidirectional_bfs.v`](../../../v/b/bidirectional_bfs.v) |
| Zig | [`zig/b/bidirectional_bfs.zig`](../../../zig/b/bidirectional_bfs.zig) |
