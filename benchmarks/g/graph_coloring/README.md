# Graph coloring count

Count the proper vertex colorings of a bounded simple undirected graph using the source's recursive backtracking order.

## Contract

- ABI: signed i64 array to byte output. Input is `[n, m, row_mask_0, ..., row_mask_(n-1)]`; bit `j` in row mask `i` means vertex `i` is adjacent to vertex `j`.
- `1 <= n <= 8`, `1 <= m <= 4`; each row mask is in `[0, 2^n)`. The graph must be symmetric with a zero diagonal.
- Count assignments using `m` distinct labeled colors. The source C++ labels them `1..m` and Rust labels them `0..m-1`; the count is unchanged by this label offset. Vertices are assigned in ascending index order, checking prior neighbors before recursing.
- The result is the count as a signed i64 encoded in 8 little-endian bytes. At most `4^8 = 65,536` assignments are possible.
- Invalid shape or graph data returns `-1`. Insufficient output capacity returns `-2` without writing.

## Source and workload

This package follows the recursive search in [TheAlgorithms/C-Plus-Plus `graph_coloring.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/backtracking/graph_coloring.cpp) and [TheAlgorithms/Rust `graph_coloring.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/backtracking/graph_coloring.rs). The C-Plus-Plus-1 source at `0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680` has the same algorithm and differs by one unused `#include <vector>`. Row masks compact the source adjacency matrix without changing its vertices or undirected edges.

The workload covers the pinned C++ sample graph, isolated and disconnected graphs, paths, cycles, complete graphs, unsatisfiable color counts, the maximum coloring count, malformed masks, and output capacity. The independent oracle uses a separate recursive enumeration over the bounded row-mask graph.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/g/graph_coloring.c`](../../../c/g/graph_coloring.c) |
| C3 | [`c3/g/graph_coloring.c3`](../../../c3/g/graph_coloring.c3) |
| C++ | [`cpp/g/graph_coloring.cpp`](../../../cpp/g/graph_coloring.cpp) |
| Elisa | [`elisa/g/graph_coloring.elisa`](../../../elisa/g/graph_coloring.elisa) |
| Nim | [`nim/g/graph_coloring.nim`](../../../nim/g/graph_coloring.nim) |
| Odin | [`odin/g/graph_coloring.odin`](../../../odin/g/graph_coloring.odin) |
| Rust | [`rust/g/graph_coloring.rs`](../../../rust/g/graph_coloring.rs) |
| V | [`v/g/graph_coloring.v`](../../../v/g/graph_coloring.v) |
| Zig | [`zig/g/graph_coloring.zig`](../../../zig/g/graph_coloring.zig) |
