# Bipartite matching: Kuhn DFS

Compute maximum cardinality matching with Kuhn's DFS augmenting-path method.
For each unmatched left vertex, the search visits right vertices once in that
augmentation and reroutes an existing match when possible.

## Contract

This variant uses the same input and result contract as
[`hopcroft_karp_cardinality`](../../h/hopcroft_karp_cardinality/README.md).
The packed `i64` input is
`[left_count, right_count, edge_count, left_0, right_0, ...]` with zero-based
endpoints, at most 64 vertices on either side and at most 4096 edge records.
Duplicate edges are accepted as one adjacency. The result is maximum matching
cardinality; null or malformed input returns `-1`.

Both algorithm names share the graph encoding. Kuhn's method and Hopcroft–Karp remain
separate benchmark variants because their augmentation strategies differ.
The scalar verifier uses an independent unit-capacity flow reference for this
package and compares it with the other matching reference on generated small
graphs. The registration and recent null guards are unverified.

The ports use a dense adjacency table. Building the table takes `O(L*R + E)`
time, and at most `L` depth-first searches each scan up to `L*R` adjacency
entries, giving `O(L²*R + L*R + E)` worst-case time and
`O(L*R + L + R)` auxiliary space. `L`, `R`, and `E` are left vertices, right
vertices, and input edge records, respectively.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/bipartite_matching_kuhn.c`](../../../c/b/bipartite_matching_kuhn.c) |
| C3 | [`c3/b/bipartite_matching_kuhn.c3`](../../../c3/b/bipartite_matching_kuhn.c3) |
| C++ | [`cpp/b/bipartite_matching_kuhn.cpp`](../../../cpp/b/bipartite_matching_kuhn.cpp) |
| Elisa | [`elisa/b/bipartite_matching_kuhn.elisa`](../../../elisa/b/bipartite_matching_kuhn.elisa) |
| Mojo | [`mojo/b/bipartite_matching_kuhn.mojo`](../../../mojo/b/bipartite_matching_kuhn.mojo) |
| Nim | [`nim/b/bipartite_matching_kuhn.nim`](../../../nim/b/bipartite_matching_kuhn.nim) |
| Odin | [`odin/b/bipartite_matching_kuhn.odin`](../../../odin/b/bipartite_matching_kuhn.odin) |
| Rust | [`rust/b/bipartite_matching_kuhn.rs`](../../../rust/b/bipartite_matching_kuhn.rs) |
| V | [`v/b/bipartite_matching_kuhn.v`](../../../v/b/bipartite_matching_kuhn.v) |
| Zig | [`zig/b/bipartite_matching_kuhn.zig`](../../../zig/b/bipartite_matching_kuhn.zig) |

## TheAlgorithms source

- [Rust `bipartite_matching.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/graph/bipartite_matching.rs) exposes both Kuhn and Hopcroft–Karp.
