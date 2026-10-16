# Undirected weighted graph

This package models the pinned Lua `undirected_graph` data structure, its connected-component iterator, and its Prim and Kruskal minimum-spanning-forest methods. The default `msf` method aliases Prim.

## Contract

Input is a signed-i64 array `[n, m, (u, v, weight)*, q, (opcode, u, v, weight)*]` with exact length `3 + 3*m + 4*q`. The graph has 0..8 fixed vertices labeled `0..n-1`, at most 28 initial undirected edges, and 0..128 operations. Every initial pair is supplied once with `u < v`; self-loops are outside the benchmark domain. Weights are integers in `[-1,000,000, 1,000,000]`, and active edges must have distinct weights. The edge-list input is normalized into the symmetric adjacency table expected by the source constructor.

Operations are four-word records:

- `0`: set or replace the edge `(u, v)` with `weight`.
- `1`: remove `(u, v)`; a missing edge is a no-op. `weight` must be zero.
- `2`: query whether `(u, v)` exists. `weight` must be zero.
- `3`: count connected components. All three trailing fields must be zero.
- `4`: run `msf_prim`; all trailing fields must be zero.
- `5`: run `msf_kruskal`; all trailing fields must be zero.
- `6`: run the default `msf` alias to Prim; all trailing fields must be zero.

Endpoints for operations 0..2 must name distinct existing vertices. Setting an edge to its current weight is valid. A new or changed edge may not reuse the weight of another active edge. Unsupported operations, malformed unused fields, duplicate initial pairs or weights, and out-of-range fields return `-1`.

The FNV-1a-64 stream records each operation as `opcode u8, result-code u8`; the result code is 0 for mutations and summary methods, and 0/1 for edge-existence queries. Component-count operations append the count as `u8`. Each MSF operation appends its component count as `u8` and a canonical forest-edge mask as `u32` little-endian. Mask bits correspond to unordered pairs in lexicographic order: `(0,1), (0,2), ...`. Unique active weights give the MSF a unique edge set, independent of the source's arbitrary node and edge iteration order.

Finally, the stream includes a canonical snapshot of the final graph: `n u8`, active edge count `u8`, then each active edge in lexicographic `(u,v)` order as `u u8, v u8, weight signed-i32 little-endian`. This makes initial graphs and mutation-only traces observable. The final FNV value is masked to 63 bits so `-1` remains the malformed-input sentinel.

The source's `new` method mirrors one-sided adjacency entries, `set_weight` updates both directions, and `remove_edge` leaves an absent edge unchanged. Node, neighbor, and edge iterators may return elements in any order, so the benchmark emits canonical edge masks and final snapshots rather than iterator order.

See [`workload.json`](workload.json), the [oracle](../../undirected_graph_oracle.py), and the pinned [Lua undirected graph](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/data_structures/undirected_graph.lua), [base graph](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/data_structures/graph.lua), [table heap](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/data_structures/table_heap.lua), [heap](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/data_structures/heap.lua), and [union-find](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/data_structures/union_find.lua).

| Language | Port |
|---|---|
| C | [`c/u/undirected_graph.c`](../../../c/u/undirected_graph.c) |
| C3 | [`c3/u/undirected_graph.c3`](../../../c3/u/undirected_graph.c3) |
| C++ | [`cpp/u/undirected_graph.cpp`](../../../cpp/u/undirected_graph.cpp) |
| Elisa | [`elisa/u/undirected_graph.elisa`](../../../elisa/u/undirected_graph.elisa) |
| Nim | [`nim/u/undirected_graph.nim`](../../../nim/u/undirected_graph.nim) |
| Odin | [`odin/u/undirected_graph.odin`](../../../odin/u/undirected_graph.odin) |
| Rust | [`rust/u/undirected_graph.rs`](../../../rust/u/undirected_graph.rs) |
| V | [`v/u/undirected_graph.v`](../../../v/u/undirected_graph.v) |
| Zig | [`zig/u/undirected_graph.zig`](../../../zig/u/undirected_graph.zig) |
