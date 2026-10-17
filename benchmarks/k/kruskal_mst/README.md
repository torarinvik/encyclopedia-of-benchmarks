# Kruskal minimum spanning tree

This benchmark combines the pinned JavaScript and R implementations of
Kruskal's algorithm for connected, undirected, weighted simple graphs. The
unique-weight restriction makes the selected spanning tree independent of the
sources' different edge enumeration orders.

## Contract

The `i64_array_scalar` input is `[vertex_count, edge_count, (u, v, weight)*]`.
There are 1–64 vertices, numbered from zero, and exactly `edge_count` triples.
For one vertex, only an empty edge list is valid. For larger graphs, the graph
must be connected and simple, with between `vertex_count - 1` and
`vertex_count * (vertex_count - 1) / 2` edges. Self-loops and repeated
undirected endpoint pairs are invalid. Edge weights are unique signed integers
in -1,000,000..1,000,000. Input edge direction and order do not affect the
result. The largest valid packet has 6,050 words; 6,051 words are parseable so
trailing input can be rejected.

The result represents both the MST edge set and its total weight. Normalize
each selected edge to `(min(u,v), max(u,v))`, then sort the edges by increasing
weight. Hash this little-endian byte stream with FNV-1a-64 and return its low
63 bits:

1. `vertex_count:u16`, `mst_edge_count:u16`;
2. for each normalized edge: `u:u16`, `v:u16`, `weight:i32`;
3. total MST weight as signed `i64`.

The FNV-1a offset basis is `14695981039346656037`; the prime is `1099511628211`.
All numeric fields use two's-complement little-endian encoding. Malformed,
disconnected, nonsimple, or non-unique-weight input returns `-1`.

The independent oracle uses Prim's algorithm rather than Kruskal's, then
normalizes the unique MST before hashing. Workload cases cover negative and
positive weights, input edge-order and orientation changes, a tree, a dense
graph, the one-vertex case, and invalid graph shapes.

## Pinned sources

- JavaScript [`KruskalMST.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Graphs/KruskalMST.js)
- R [`kruskal_mst.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/Desktop/open-source/R/graph_algorithms/kruskal_mst.r)

The JavaScript source builds an undirected adjacency list and stops after
accepting `vertex_count - 1` edges; the R source scans all edges through a
disjoint set. This contract requires connected graphs so both produce an MST.
The source graph's symmetric edges, R's one-based endpoints, and returned edge
orientation/order are normalized by the wrapper. Unique weights remove
source-specific tie ordering. Vertices are encoded as contiguous zero-based
IDs; the JavaScript wrapper adds all vertices before adding edges, and the R
wrapper translates IDs to one-based indices.

## Workload

The workload is [`workload.json`](workload.json); the direct Prim oracle is
[`benchmarks/kruskal_mst_oracle.py`](../../kruskal_mst_oracle.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/k/kruskal_mst.c`](../../../c/k/kruskal_mst.c) |
| C3 | [`c3/k/kruskal_mst.c3`](../../../c3/k/kruskal_mst.c3) |
| C++ | [`cpp/k/kruskal_mst.cpp`](../../../cpp/k/kruskal_mst.cpp) |
| Elisa | [`elisa/k/kruskal_mst.elisa`](../../../elisa/k/kruskal_mst.elisa) |
| Nim | [`nim/k/kruskal_mst.nim`](../../../nim/k/kruskal_mst.nim) |
| Odin | [`odin/k/kruskal_mst.odin`](../../../odin/k/kruskal_mst.odin) |
| Rust | [`rust/k/kruskal_mst.rs`](../../../rust/k/kruskal_mst.rs) |
| V | [`v/k/kruskal_mst.v`](../../../v/k/kruskal_mst.v) |
| Zig | [`zig/k/kruskal_mst.zig`](../../../zig/k/kruskal_mst.zig) |
