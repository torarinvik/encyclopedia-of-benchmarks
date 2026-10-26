# GBBS Shiloach–Vishkin spanning forest

This package extracts the unweighted spanning-forest edge generation from
GBBS's Shiloach–Vishkin variant. It returns a membership byte for each input
edge, in input order.

## Contract

- Exported symbol: `gbbs_shiloach_vishkin_spanning_forest`; ABI:
  `i64_array_bytes_output`.
- Input: `[node_count, edge_count, (u, v)...]`.
- Bounds: `1 <= node_count <= 12`, `0 <= edge_count <= 24`, exact input length
  `2 + 2*edge_count`.
- The graph is simple and undirected; each edge appears once in canonical
  form `u < v`.
- Output is one byte per supplied edge, in input order: `1` if that edge is
  selected for the forest and `0` otherwise. Success returns edge_count
  bytes; invalid input returns -1; null output or insufficient capacity
  returns -2 without writing.
- The maximum input length is 50 integers; maximum output is 24 bytes.

The profile preserves the source's min-root hooking rounds. It starts with one
parent root per vertex. On each round, every component root with a lower-ID
neighbor root hooks to its smallest such neighbor root. Parent paths are
compressed before the next round. The source stores an edge witness for each
successful root hook; this profile chooses the lowest input-edge ordinal
between the two old-round components to resolve its parallel compare-and-swap
choice. Output order is canonicalized to the input edge list.

This shares the root-hooking and parent-compression recurrence with the local
[`gapbs_shiloach_vishkin_components`](../../a/gapbs_shiloach_vishkin_components/README.md)
profile, which emits component labels. This package captures the distinct
edge-witness output and returns an actual unweighted spanning forest. Weighted
Kruskal/Borůvka packages optimize edge weights, while the local BFS tree
profile explores from one source; neither has this whole-graph hook-edge
contract. The selected edges form a forest with one tree per input connected
component.

## Source and rights

Pinned source: GBBS commit
[`dbd1dcad582c0a316c5ba0d5524319d596dd82da`](https://github.com/ParAlg/gbbs/tree/dbd1dcad582c0a316c5ba0d5524319d596dd82da):
[`SpanningForest.h`](https://github.com/ParAlg/gbbs/blob/dbd1dcad582c0a316c5ba0d5524319d596dd82da/benchmarks/SpanningForest/ShiloachVishkin/SpanningForest.h)
and
[`SpanningForest.cc`](https://github.com/ParAlg/gbbs/blob/dbd1dcad582c0a316c5ba0d5524319d596dd82da/benchmarks/SpanningForest/ShiloachVishkin/SpanningForest.cc).
The profile follows `SVAlgorithm::compute_spanning_forest` and
`shiloachvishkin_sf::SpanningForest`. GBBS is MIT licensed; the complete notice
is included in `LICENSE.txt`. The ports are clean-room implementations.

## Ports

| Language | Source |
| --- | --- |
| C | `c/g/gbbs_shiloach_vishkin_spanning_forest.c` |
| C3 | `c3/g/gbbs_shiloach_vishkin_spanning_forest.c3` |
| C++ | `cpp/g/gbbs_shiloach_vishkin_spanning_forest.cpp` |
| Elisa | `elisa/g/gbbs_shiloach_vishkin_spanning_forest.elisa` |
| Nim | `nim/g/gbbs_shiloach_vishkin_spanning_forest.nim` |
| Odin | `odin/g/gbbs_shiloach_vishkin_spanning_forest.odin` |
| Rust | `rust/g/gbbs_shiloach_vishkin_spanning_forest.rs` |
| V | `v/g/gbbs_shiloach_vishkin_spanning_forest.v` |
| Zig | `zig/g/gbbs_shiloach_vishkin_spanning_forest.zig` |

The primary oracle models GBBS parent-hook rounds and records each hook edge.
The independent verifier discovers components from the selected-forest edges
and advances them by deterministic lower-root hooks.
