# Bipartite matching: Hopcroft–Karp

Compute the maximum cardinality matching of a bipartite graph with separate
left and right vertex sets. The benchmark uses Hopcroft–Karp, one of the two
maximum-matching methods exposed by the pinned Rust source. Kuhn's augmenting
path method is also present there; this contract standardizes on Hopcroft–Karp.

## Contract

The packed `i64` input is
`[left_count, right_count, edge_count, left_0, right_0, ...]`.

- Each partition contains `0..=64` vertices, indexed from zero.
- `edge_count` is `0..=4096`; each endpoint must identify a vertex in its
  partition. Duplicate edges are accepted and treated as one adjacency.
- The packed length must be exactly `3 + 2 * edge_count`.
- The result is the maximum number of pairwise vertex-disjoint edges.
- Malformed shape, count, or endpoint returns `-1`. An empty graph returns
  `0`.

The bounded array adjacency representation uses at most 4096 entries. It
supports unequal partition sizes and isolated vertices.

## Related benchmarks

There was no existing bipartite maximum-matching benchmark in the repository.
Stable matching has preference constraints, and bipartite graph recognition
only decides whether a graph can be split into two sets. Neither computes
maximum matching cardinality.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/bipartite_matching_hopcroft_karp.c`](../../../c/b/bipartite_matching_hopcroft_karp.c) |
| C3 | [`c3/b/bipartite_matching_hopcroft_karp.c3`](../../../c3/b/bipartite_matching_hopcroft_karp.c3) |
| C++ | [`cpp/b/bipartite_matching_hopcroft_karp.cpp`](../../../cpp/b/bipartite_matching_hopcroft_karp.cpp) |
| Elisa | [`elisa/b/bipartite_matching_hopcroft_karp.elisa`](../../../elisa/b/bipartite_matching_hopcroft_karp.elisa) |
| Nim | [`nim/b/bipartite_matching_hopcroft_karp.nim`](../../../nim/b/bipartite_matching_hopcroft_karp.nim) |
| Odin | [`odin/b/bipartite_matching_hopcroft_karp.odin`](../../../odin/b/bipartite_matching_hopcroft_karp.odin) |
| Rust | [`rust/b/bipartite_matching_hopcroft_karp.rs`](../../../rust/b/bipartite_matching_hopcroft_karp.rs) |
| V | [`v/b/bipartite_matching_hopcroft_karp.v`](../../../v/b/bipartite_matching_hopcroft_karp.v) |
| Zig | [`zig/b/bipartite_matching_hopcroft_karp.zig`](../../../zig/b/bipartite_matching_hopcroft_karp.zig) |

## TheAlgorithms source

- [Rust `bipartite_matching.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/graph/bipartite_matching.rs) exposes both Kuhn and Hopcroft–Karp algorithms over an adjacency list.
