# Bounded-degree bipartiteness random-walk tester

This package implements the parity-collision kernel described in Oded Goldreich and Dana Ron's *Encyclopedia of Algorithms* chapter “Testing Bipartiteness of Graphs in Sublinear Time,” DOI [`10.1007/978-1-4939-2864-4_701`](https://doi.org/10.1007/978-1-4939-2864-4_701). For each supplied start vertex, it runs bounded random walks with the chapter's lazy transition rule and rejects when some vertex is reached at both even and odd real-walk parity.

## Bounded contract

- ABI: `i64_array_bytes_output`; input is `[N,d,m,u0,v0,...,T,R,L,s0,...,s(T-1),draws...]`.
- `1 <= N <= 16`, degree bound `3 <= d <= 4`, and the input graph is simple, undirected, and has maximum degree at most `d`. Edges use canonical pairs `0 <= u < v < N`.
- There are `1..4` start vertices, `1..8` walks per start, and `1..8` steps per walk. Start vertices may repeat. Each supplied draw is an integer in `0..2d-1`; choices are ordered by start, walk, then step.
- Neighbors are indexed in ascending vertex-ID order. At a step from `v`, a draw smaller than `degree(v)` traverses that indexed edge and flips parity; all other draws are lazy self-loops and do not affect real-edge parity. For a start, `R0` and `R1` are the vertices seen with even and odd real-edge counts over all its walks, including the start in `R0`. Reject if the sets intersect for any start; otherwise accept.
- Output is `[accept_bit]`, one little-endian signed 64-bit word (8 bytes). Invalid input returns `-1`; null or short output returns `-2` without writes. Maximum input length is 330 words.
- The random starts and transition choices are supplied to make one execution reproducible. This package implements the walk/query decision kernel, not the chapter's probabilistic query-count schedule or rapid-mixing soundness proof. A fixed supplied trace can accept a graph far from bipartite.

The profile is distinct from exact [full-graph bipartite recognition](../b/bipartite_graph_dfs/README.md), which traverses all graph edges, and from the [dense-model induced-sample tester](../d/dense_graph_bipartiteness_tester/README.md), which samples vertices and queries all pairs among them rather than running lazy incidence walks.

## Provenance and rights

Source attribution: Oded Goldreich and Dana Ron, “Testing Bipartiteness of Graphs in Sublinear Time,” *Encyclopedia of Algorithms*, DOI `10.1007/978-1-4939-2864-4_701`. The chapter and summarized papers remain copyrighted; this clean-room package copies no source code, prose, or figures and asserts no redistribution license for those materials. See [`RIGHTS.md`](RIGHTS.md).

## Package files

- [`workload.json`](workload.json)
- [primary adjacency-list oracle](../../sublinear_bipartiteness_walk_tester_oracle.py)
- [independent bitset verifier oracle](../../sublinear_bipartiteness_walk_tester_verifier_oracle.py)

| Language | Port |
|---|---|
| C | [`c/t/sublinear_bipartiteness_walk_tester.c`](../../../c/t/sublinear_bipartiteness_walk_tester.c) |
| C3 | [`c3/t/sublinear_bipartiteness_walk_tester.c3`](../../../c3/t/sublinear_bipartiteness_walk_tester.c3) |
| C++ | [`cpp/t/sublinear_bipartiteness_walk_tester.cpp`](../../../cpp/t/sublinear_bipartiteness_walk_tester.cpp) |
| Elisa | [`elisa/t/sublinear_bipartiteness_walk_tester.elisa`](../../../elisa/t/sublinear_bipartiteness_walk_tester.elisa) |
| Nim | [`nim/t/sublinear_bipartiteness_walk_tester.nim`](../../../nim/t/sublinear_bipartiteness_walk_tester.nim) |
| Odin | [`odin/t/sublinear_bipartiteness_walk_tester.odin`](../../../odin/t/sublinear_bipartiteness_walk_tester.odin) |
| Rust | [`rust/t/sublinear_bipartiteness_walk_tester.rs`](../../../rust/t/sublinear_bipartiteness_walk_tester.rs) |
| V | [`v/t/sublinear_bipartiteness_walk_tester.v`](../../../v/t/sublinear_bipartiteness_walk_tester.v) |
| Zig | [`zig/t/sublinear_bipartiteness_walk_tester.zig`](../../../zig/t/sublinear_bipartiteness_walk_tester.zig) |
