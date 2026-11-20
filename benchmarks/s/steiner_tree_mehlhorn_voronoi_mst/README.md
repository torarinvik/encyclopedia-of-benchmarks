# Mehlhorn Steiner tree by Voronoi and sparse terminal MST

This package implements Mehlhorn's bounded Voronoi-crossing-edge construction
for a graph Steiner tree. The primary computes a nearest-terminal region for
each graph vertex, keeps the cheapest crossing-edge witness for each terminal
pair, finds an MST of this sparse terminal graph, expands the selected witness
paths, takes an MST of their union, and removes nonterminal leaves. This is a
deterministic small-graph profile; it does not claim the paper's asymptotic
running time.

## Contract

The exported symbol is `steiner_tree_mehlhorn_voronoi_mst` with the
`i64_array_bytes_output` ABI. Input is:

```text
[n,m,k, terminal_ids[k], (u,v,weight)*m]
```

The graph is connected, undirected, simple, and encoded with `0<=u<v<n`.
There are `2<=n<=8`, `1<=m<=14`, and `2<=k<=n` distinct terminals. Edge
weights are integers in `[1,9]`; positive weights make the selected shortest
path predecessor relation acyclic. The input length is exactly `3+k+3*m`:
at most 53 valid i64 words, with 54 parseable words for one malformed trailing
word.

Multi-source Dijkstra uses `(distance, terminal_id, vertex_id)` ordering. Equal
distance regions belong to the lower terminal ID. Within one region, equal
shortest-path predecessor choices use the lowest `(predecessor_vertex,
edge_id)`. For each crossing edge, terminals are ordered by ID; equal candidate
weights choose the lowest oriented endpoint pair and then edge ID. Candidate
MST ties use `(candidate_weight, terminal_a, terminal_b, endpoint_a,
endpoint_b, edge_id)`. The expanded-union MST uses `(original_edge_weight,
edge_id)`. Nonterminal leaves are repeatedly removed. Output edge IDs are
sorted in ascending input order.

Output is little-endian signed i64 bytes:

```text
[tree_cost, tree_edge_count, ascending_original_edge_ids...]
```

The maximum output buffer is 72 bytes (two header words and at most seven
tree edge IDs, since a tree on eight vertices has at most seven edges). Invalid input returns `-1`. Null output or insufficient capacity
returns `-2` without writing. The bounded workspace cap is 8,192 bytes,
including graph, distance, candidate, predecessor, DSU, expansion, queue, and
staging storage.

The primary oracle mirrors the source's Voronoi region and boundary-edge
construction using multi-source Dijkstra and Kruskal. The independent oracle
computes all terminal distance maps with per-source Bellman–Ford relaxation,
then exhaustively enumerates sparse terminal-graph spanning trees and the
expanded-union MST. It uses neither the primary's multi-source priority rule
nor Kruskal transitions.

## Distinctness and sources

This is distinct from local [`steiner_tree_subset_dp`](../steiner_tree_subset_dp/README.md),
which computes an exact optimum by terminal-subset dynamic programming, and
[`steiner_tree_gain_greedy`](../steiner_tree_gain_greedy/README.md), which
selects from an explicit family of full components by a gain potential. This
profile measures nearest-terminal partitioning, crossing-edge sparsification,
and witness expansion.

Operational source: Kurt Mehlhorn, [“A Faster Approximation Algorithm for the
Steiner Problem in Graphs,” *Information Processing Letters* 27(3), 125–128
(1988), §2, Lemma 2.2, Theorem 2.3](https://doi.org/10.1016/0020-0190(88)90066-X).
Chapter context: Weili Wu and Yaocun Huang, [“Steiner Trees,” *Encyclopedia of
Algorithms*, Chapter 403](https://doi.org/10.1007/978-1-4939-2864-4_403). The
Kou–Markowsky–Berman paper is also listed in [`workload.json`](workload.json).
Only algorithm descriptions are used; the contract, fixtures, references, and
ports are clean-room work. See [`RIGHTS.md`](RIGHTS.md).

Static package helpers and workload are source artifacts only. No programs,
tests, helpers/checkers, builds, compilers, profilers, or benchmarks were run.

## Language ports

| Language | Source |
|---|---|
| C | [`c/s/steiner_tree_mehlhorn_voronoi_mst.c`](../../../c/s/steiner_tree_mehlhorn_voronoi_mst.c) |
| C3 | [`c3/s/steiner_tree_mehlhorn_voronoi_mst.c3`](../../../c3/s/steiner_tree_mehlhorn_voronoi_mst.c3) |
| C++ | [`cpp/s/steiner_tree_mehlhorn_voronoi_mst.cpp`](../../../cpp/s/steiner_tree_mehlhorn_voronoi_mst.cpp) |
| Elisa | [`elisa/s/steiner_tree_mehlhorn_voronoi_mst.elisa`](../../../elisa/s/steiner_tree_mehlhorn_voronoi_mst.elisa) |
| Mojo | [`mojo/s/steiner_tree_mehlhorn_voronoi_mst.mojo`](../../../mojo/s/steiner_tree_mehlhorn_voronoi_mst.mojo) |
| Nim | [`nim/s/steiner_tree_mehlhorn_voronoi_mst.nim`](../../../nim/s/steiner_tree_mehlhorn_voronoi_mst.nim) |
| Odin | [`odin/s/steiner_tree_mehlhorn_voronoi_mst.odin`](../../../odin/s/steiner_tree_mehlhorn_voronoi_mst.odin) |
| Rust | [`rust/s/steiner_tree_mehlhorn_voronoi_mst.rs`](../../../rust/s/steiner_tree_mehlhorn_voronoi_mst.rs) |
| V | [`v/s/steiner_tree_mehlhorn_voronoi_mst.v`](../../../v/s/steiner_tree_mehlhorn_voronoi_mst.v) |
| Zig | [`zig/s/steiner_tree_mehlhorn_voronoi_mst.zig`](../../../zig/s/steiner_tree_mehlhorn_voronoi_mst.zig) |
