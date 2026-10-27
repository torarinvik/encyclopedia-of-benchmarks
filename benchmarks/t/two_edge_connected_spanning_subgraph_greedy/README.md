# Greedy 2-edge-connected spanning subgraph

This package profiles the chapter's simple critical-edge deletion heuristic
for the `k`-connected spanning-subgraph problem at fixed `k=2` edge
connectivity. It starts with a supplied 2-edge-connected simple graph and
considers each input edge once, in input order. It deletes an edge exactly
when the remaining graph is still 2-edge-connected. Here that test means the
remaining graph is connected after deletion of any one of its edges; this is
edge connectivity, not vertex connectivity. The result is an inclusion-minimal
2-edge-connected spanning subgraph. Output edges are sorted lexicographically
for canonical serialization; input edge order controls the heuristic.

## Contract

ABI: `i64_array_bytes_output`; symbol:
`two_edge_connected_spanning_subgraph_greedy`.
Input is `[n,m,(u,v)[m]]` with zero-based vertices and `u<v`.

- `3<=n<=8`, `3<=m<=28`; the graph is simple and the input must already be
  2-edge-connected. Edge records appear in the exact order in which the
  source heuristic considers them; they need not be sorted.
- Initial validity and every tentative deletion are checked by requiring
  connectivity both before and after removal of each remaining single edge.
- Output is `[remaining_edge_count,(u,v)[remaining_edge_count]]`, sorted by
  endpoint pair and serialized as little-endian signed i64. Maximum input is
  58 words (59 parseable); maximum output is 456 bytes. Invalid input returns
  `-1`; null or insufficient output returns `-2` with no writes.

The chapter calls this simple algorithm a 2-approximation for minimum-size
2-connected spanning subgraphs: the returned graph has only critical edges
and at most `2n` edges. This profile represents only the `k=2` edge-connected
case of that algorithm. It does not implement vertex-connectivity augmentation,
the DFS-based 3/2 method, matching-based algorithms, or the improved small-k
variants.

Source: Samir Khuller and Balaji Raghavachari, “Graph Connectivity,”
*Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_171`](https://doi.org/10.1007/978-1-4939-2864-4_171),
Problem Definition and the simple approximation algorithm discussion. The
chapter grants no source-code license. The ports and oracles are clean-room
implementations of the described edge-removal rule; no book prose or code is
copied. See [RIGHTS.md](RIGHTS.md).

| Language | Port |
|---|---|
| C | `c/t/two_edge_connected_spanning_subgraph_greedy.c` |
| C3 | `c3/t/two_edge_connected_spanning_subgraph_greedy.c3` |
| C++ | `cpp/t/two_edge_connected_spanning_subgraph_greedy.cpp` |
| Elisa | `elisa/t/two_edge_connected_spanning_subgraph_greedy.elisa` |
| Nim | `nim/t/two_edge_connected_spanning_subgraph_greedy.nim` |
| Odin | `odin/t/two_edge_connected_spanning_subgraph_greedy.odin` |
| Rust | `rust/t/two_edge_connected_spanning_subgraph_greedy.rs` |
| V | `v/t/two_edge_connected_spanning_subgraph_greedy.v` |
| Zig | `zig/t/two_edge_connected_spanning_subgraph_greedy.zig` |

See [workload.json](workload.json), [primary oracle](../../two_edge_connected_spanning_subgraph_greedy_oracle.py),
and [independent verifier](../../two_edge_connected_spanning_subgraph_greedy_verifier_oracle.py).
