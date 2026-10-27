# Clique reverse-search enumeration

This profile implements the clique-specific reverse-search example in the
chapter. It enumerates all cliques of a simple undirected graph, including the
empty clique and every nonmaximal clique. The root is the empty clique. The
parent of any nonempty clique removes its smallest-index vertex, so a child
adds a vertex smaller than every vertex already present and adjacent to every
vertex in the current clique. Eligible added vertices are visited in
increasing order, using depth-first preorder.

Input is `[n, adjacency_mask_0,...,adjacency_mask_(n-1)]`, with `1<=n<=8`.
Masks are symmetric, exclude self bits, and use bit `v` for vertex `v`. Output
starts with an eight-byte little-endian clique count, followed by one byte per
clique mask in traversal order. The empty clique has mask zero. Invalid input
returns `-1`; null output or insufficient capacity returns `-2` without
writing. The complete eight-vertex graph reaches the 264-byte output bound.

The primary oracle generates eligible smaller-index extensions directly. The
independent verifier enumerates every vertex subset, retains cliques, derives
each parent by removing the least significant set bit, and orders children by
the added vertex. This enumerates all cliques, unlike local
[`bron_kerbosch`](../../b/bron_kerbosch/README.md), which enumerates maximal
cliques only. It uses the reverse-search framework from DOI 731; the
permutation-specific reverse-search tree from DOI 735 is a separate profile.

Primary oracle: [`clique_reverse_search_enumeration_oracle.py`](../../clique_reverse_search_enumeration_oracle.py).
Independent verifier: [`clique_reverse_search_enumeration_verifier_oracle.py`](../../clique_reverse_search_enumeration_verifier_oracle.py).

Source: “Reverse Search; Enumeration Algorithms,” Masashi Kiyomi,
*Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_731`](https://doi.org/10.1007/978-1-4939-2864-4_731).
The chapter is used only for algorithm attribution and the parent rule; no
book code, prose, or figures were copied. The half-space/polytope example is
outside this bounded profile because it requires a specified LP instance and
pivot model.

## Workload and ports

The [workload](workload.json) covers an empty graph, a path, a complete
maximum-size graph, malformed graph encodings, null buffers, and a short
capacity probe.

| Language | Port |
|---|---|
| C | `c/r/clique_reverse_search_enumeration.c` |
| C3 | `c3/r/clique_reverse_search_enumeration.c3` |
| C++ | `cpp/r/clique_reverse_search_enumeration.cpp` |
| Elisa | `elisa/r/clique_reverse_search_enumeration.elisa` |
| Nim | `nim/r/clique_reverse_search_enumeration.nim` |
| Odin | `odin/r/clique_reverse_search_enumeration.odin` |
| Rust | `rust/r/clique_reverse_search_enumeration.rs` |
| V | `v/r/clique_reverse_search_enumeration.v` |
| Zig | `zig/r/clique_reverse_search_enumeration.zig` |
