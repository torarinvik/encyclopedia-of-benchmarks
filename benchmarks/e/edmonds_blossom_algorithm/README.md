# Edmonds blossom maximum matching

Find a maximum-cardinality matching in a simple undirected general graph.
Unlike Kuhn and Hopcroft–Karp matching, the graph has no left/right partition;
the augmenting-path search contracts odd cycles (blossoms) so it can proceed
through non-bipartite graphs.

## Contract

The packed `i64` input is `[vertex_count, edge_count, u_0, v_0, ...]`.

- `vertex_count` is from 0 through 20 and `edge_count` from 0 through 190.
- Vertices use zero-based indices. Every edge has two distinct in-range endpoints.
- Reversed and duplicate edge records are accepted and treated as one edge.
- The packed length must equal `2 + 2 * edge_count`.
- Return the maximum number of disjoint edges; malformed input returns `-1`.

The 20-vertex bound keeps the independent subset recurrence used by the oracle
small while still exercising blossom contraction. The benchmark ports use
Edmonds' O(V^3) augmenting-path algorithm.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/e/edmonds_blossom_algorithm.c`](../../../c/e/edmonds_blossom_algorithm.c) |
| C3 | [`c3/e/edmonds_blossom_algorithm.c3`](../../../c3/e/edmonds_blossom_algorithm.c3) |
| C++ | [`cpp/e/edmonds_blossom_algorithm.cpp`](../../../cpp/e/edmonds_blossom_algorithm.cpp) |
| Elisa | [`elisa/e/edmonds_blossom_algorithm.elisa`](../../../elisa/e/edmonds_blossom_algorithm.elisa) |
| Nim | [`nim/e/edmonds_blossom_algorithm.nim`](../../../nim/e/edmonds_blossom_algorithm.nim) |
| Odin | [`odin/e/edmonds_blossom_algorithm.odin`](../../../odin/e/edmonds_blossom_algorithm.odin) |
| Rust | [`rust/e/edmonds_blossom_algorithm.rs`](../../../rust/e/edmonds_blossom_algorithm.rs) |
| V | [`v/e/edmonds_blossom_algorithm.v`](../../../v/e/edmonds_blossom_algorithm.v) |
| Zig | [`zig/e/edmonds_blossom_algorithm.zig`](../../../zig/e/edmonds_blossom_algorithm.zig) |

## Pinned sources

- [Java implementation](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/graphs/EdmondsBlossomAlgorithm.java)
- [Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/edmonds_blossom_algorithm.py)

The Java implementation contracts blossoms during BFS and returns matched
pairs. The Python implementation has the same intended method, but its pinned
`contract_blossom` path loops use a boolean comparison as the range endpoint,
so they do not walk the alternating paths as intended. The shared contract
uses the standard Edmonds contraction procedure and compares cardinality.
