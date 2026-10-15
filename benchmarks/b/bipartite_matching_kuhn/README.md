# Bipartite matching: Kuhn DFS

Compute maximum cardinality matching with Kuhn's DFS augmenting-path method.
For each unmatched left vertex, the search visits right vertices once in that
augmentation and reroutes an existing match when possible.

## Contract

This variant uses the same input and result contract as
[`bipartite_matching_hopcroft_karp`](../bipartite_matching_hopcroft_karp/README.md).
The packed `i64` input is
`[left_count, right_count, edge_count, left_0, right_0, ...]` with zero-based
endpoints, at most 64 vertices on either side and at most 4096 edge records.
Duplicate edges are accepted as one adjacency. The result is maximum matching
cardinality; malformed input returns `-1`.

Both algorithm names share the graph encoding and workload cases so their
results compare on identical graphs. Kuhn's method and Hopcroft–Karp remain
separate benchmark variants because their augmentation strategies differ.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/bipartite_matching_kuhn.c`](../../../c/b/bipartite_matching_kuhn.c) |
| C3 | [`c3/b/bipartite_matching_kuhn.c3`](../../../c3/b/bipartite_matching_kuhn.c3) |
| C++ | [`cpp/b/bipartite_matching_kuhn.cpp`](../../../cpp/b/bipartite_matching_kuhn.cpp) |
| Elisa | [`elisa/b/bipartite_matching_kuhn.elisa`](../../../elisa/b/bipartite_matching_kuhn.elisa) |
| Nim | [`nim/b/bipartite_matching_kuhn.nim`](../../../nim/b/bipartite_matching_kuhn.nim) |
| Odin | [`odin/b/bipartite_matching_kuhn.odin`](../../../odin/b/bipartite_matching_kuhn.odin) |
| Rust | [`rust/b/bipartite_matching_kuhn.rs`](../../../rust/b/bipartite_matching_kuhn.rs) |
| V | [`v/b/bipartite_matching_kuhn.v`](../../../v/b/bipartite_matching_kuhn.v) |
| Zig | [`zig/b/bipartite_matching_kuhn.zig`](../../../zig/b/bipartite_matching_kuhn.zig) |

## TheAlgorithms source

- [Rust `bipartite_matching.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/graph/bipartite_matching.rs) exposes both Kuhn and Hopcroft–Karp.
