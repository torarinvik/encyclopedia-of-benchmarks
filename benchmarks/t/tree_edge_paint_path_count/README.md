# Tree edge painting with path counts

Maintain an initially unpainted undirected tree. A paint operation permanently
marks one edge; a path query reports how many marked edges lie on the unique
path between two vertices. The scalar result is the sum of all query answers in
the supplied trace.

## Contract

The exported symbol is `tree_edge_paint_path_count` with the
`i64_array_scalar` ABI. Input is
`[N,Q,(u,v)^(N-1),(opcode,a,b)^Q]`. The `N-1` edges are in stable edge-ID order
and must form a simple tree. `1<=N<=16` and `0<=Q<=32`.

- Opcode `0` paints edge ID `a`; `b` must be zero. Painting an already painted
  edge has no additional effect.
- Opcode `1` asks for the number of painted edges on the path from vertex `a`
  to vertex `b`.
- The returned scalar is the sum of answers for all path queries. Malformed
  input returns `-1`.

The exact frame length is `2+2*(N-1)+3*Q`. Maximum valid and parseable lengths
are 128 and 129 signed 64-bit words.
With at most 32 operations, the maximum checksum is 255: paint all 15 edges
first, then query the 15-edge path 17 times.

## Algorithms

The primary roots the tree at zero and records every DFS-tour edge traversal.
Each edge appears once downward and once upward. Two point-update segment
trees store painted edge occurrences by direction. For an ancestor-to-descendant
path, subtracting reverse occurrences from forward occurrences cancels
off-path excursions from the Euler tour. An arbitrary path is split at its LCA.
The bounded edge-scan traversal takes `O(N^2)` preprocessing; point updates and
path aggregates take `O(log N)` each.

The independent oracle performs a fresh BFS parent search for each path query,
reconstructs the unique path, and counts its painted edge IDs. It takes
`O(Q*N)` time and `O(N)` auxiliary space.

## Distinctness and provenance

The local dynamic-tree packages update vertex values, affine path maps, or
subtree aggregates. None supports idempotent edge painting followed by painted
edge-count queries on arbitrary paths. The source is [CP-Algorithms, “Tree
painting”](https://cp-algorithms.com/graph/tree_painting.html), licensed under
CC BY-SA 4.0; only its algorithm description informed the primary method. See
[`RIGHTS.md`](RIGHTS.md), [`workload.json`](workload.json), both oracle modules,
and the static checker
[`check_tree_edge_paint_path_count_package.py`](../../check_tree_edge_paint_path_count_package.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/t/tree_edge_paint_path_count.c`](../../../c/t/tree_edge_paint_path_count.c) |
| C3 | [`c3/t/tree_edge_paint_path_count.c3`](../../../c3/t/tree_edge_paint_path_count.c3) |
| C++ | [`cpp/t/tree_edge_paint_path_count.cpp`](../../../cpp/t/tree_edge_paint_path_count.cpp) |
| Elisa | [`elisa/t/tree_edge_paint_path_count.elisa`](../../../elisa/t/tree_edge_paint_path_count.elisa) |
| Mojo | [`mojo/t/tree_edge_paint_path_count.mojo`](../../../mojo/t/tree_edge_paint_path_count.mojo) |
| Nim | [`nim/t/tree_edge_paint_path_count.nim`](../../../nim/t/tree_edge_paint_path_count.nim) |
| Odin | [`odin/t/tree_edge_paint_path_count.odin`](../../../odin/t/tree_edge_paint_path_count.odin) |
| Rust | [`rust/t/tree_edge_paint_path_count.rs`](../../../rust/t/tree_edge_paint_path_count.rs) |
| V | [`v/t/tree_edge_paint_path_count.v`](../../../v/t/tree_edge_paint_path_count.v) |
| Zig | [`zig/t/tree_edge_paint_path_count.zig`](../../../zig/t/tree_edge_paint_path_count.zig) |
