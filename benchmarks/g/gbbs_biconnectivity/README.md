# GBBS Tarjan–Vishkin biconnectivity

This package computes the vertex-biconnected edge blocks of a bounded simple
undirected graph. Each input edge receives one canonical byte label. Edges in
the same biconnected block share a label; the label is the zero-based ordinal
of the first supplied edge in that block. A bridge is a one-edge block.
Isolated vertices produce no output entry.

## Contract

- Exported symbol: gbbs_biconnectivity; ABI: i64_array_bytes_output.
- Input: [node_count, edge_count, (u, v)...].
- Bounds: 1 <= node_count <= 12 and 0 <= edge_count <= 24. Exact input length
  is 2 + 2*edge_count.
- The graph is simple and undirected. Every edge is supplied once in canonical
  form, 0 <= u < v < node_count.
- Output contains one unsigned byte per input edge, in input order. The byte
  is the canonical block label. Success returns edge_count bytes. Invalid
  input returns -1. Null output or insufficient capacity returns -2 without
  writing. A valid graph with zero edges returns zero bytes.
- Output labels are canonicalized after computing the edge-block partition.
  They do not preserve GBBS's internal connected-component representative IDs.

The profile follows the source stages: deterministic multi-source BFS chooses
a spanning forest; children are visited in ID order for tree preorder;
subtree intervals and low/high reachability labels are propagated; critical
tree edges are removed; connected components in the remaining graph identify
edge blocks. The deterministic BFS parent rule uses the smallest parent in
the current frontier, corresponding to the deterministic helper in the pinned
header. Each component uses its smallest unvisited vertex as root, and each
tree preorder starts at zero. The source's internal connected-component IDs
are canonicalized to the smallest input-edge ordinal in each block. Parallel
scheduling and graph file I/O are excluded.

This is a biconnected edge-block partition. It differs from connected
components, SCC, articulation-point IDs, and bridge-only output. It can share
the articulation and bridge structure while assigning every edge to its
whole vertex-biconnected block.

## Source and rights

The source is pinned to GBBS commit
[dbd1dcad582c0a316c5ba0d5524319d596dd82da](https://github.com/ParAlg/gbbs/tree/dbd1dcad582c0a316c5ba0d5524319d596dd82da):
[Biconnectivity.h](https://github.com/ParAlg/gbbs/blob/dbd1dcad582c0a316c5ba0d5524319d596dd82da/benchmarks/Biconnectivity/TarjanVishkin/Biconnectivity.h)
and
[Biconnectivity.cc](https://github.com/ParAlg/gbbs/blob/dbd1dcad582c0a316c5ba0d5524319d596dd82da/benchmarks/Biconnectivity/TarjanVishkin/Biconnectivity.cc).
The key implementation stages are preorder_number, deterministic_multi_bfs,
critical_connectivity, and Biconnectivity. The launcher requires symmetric
input and writes per-vertex parent/component labels with -of. GBBS is MIT
licensed; the full notice is retained in LICENSE.txt. The ports are clean-room
implementations.

## Ports

| Language | Source |
| --- | --- |
| C | c/g/gbbs_biconnectivity.c |
| C3 | c3/g/gbbs_biconnectivity.c3 |
| C++ | cpp/g/gbbs_biconnectivity.cpp |
| Elisa | elisa/g/gbbs_biconnectivity.elisa |
| Nim | nim/g/gbbs_biconnectivity.nim |
| Odin | odin/g/gbbs_biconnectivity.odin |
| Rust | rust/g/gbbs_biconnectivity.rs |
| V | v/g/gbbs_biconnectivity.v |
| Zig | zig/g/gbbs_biconnectivity.zig |

Fixtures are in workload.json. The package oracle follows the source stages;
the independent verifier determines block equivalence by checking whether a
single deleted vertex separates any pair of edges.
