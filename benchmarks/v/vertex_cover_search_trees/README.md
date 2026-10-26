# Vertex-cover branch-and-search

This package implements a bounded exact branch-and-search profile for the
parameterized vertex-cover problem. It selects a maximum-degree active vertex,
breaking degree ties by the lowest vertex ID. One branch includes that vertex;
the other excludes it and includes all its active neighbors. The branches are
recursed on the graph induced by the remaining active vertices. The package
explores both branches, returns a minimum-size cover, and breaks equal-size
ties by the numerically lowest vertex mask. The supplied parameter affects the
decision bit, not the search result.

Input is `[n,m,k,(u,v)...]`, with `1 <= n <= 16`, `0 <= m <= 64`, `0 <= k <= n`,
and simple undirected edges given once in strictly increasing order as `u < v`.
Output is `[has_cover_of_size_at_most_k, minimum_cover_size, cover_mask]` as
three little-endian signed i64 values. Invalid input returns `-1`; null output
or capacity below 24 bytes returns `-2` without writing.

Source: “Vertex Cover Search Trees,” *Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_462`](https://doi.org/10.1007/978-1-4939-2864-4_462).
This is a clean-room implementation of its branch-and-search technique; no
book prose, pseudocode blocks, or source code are copied.

## Ports

| Language | Port |
|---|---|
| C | `c/v/vertex_cover_search_trees.c` |
| C3 | `c3/v/vertex_cover_search_trees.c3` |
| C++ | `cpp/v/vertex_cover_search_trees.cpp` |
| Elisa | `elisa/v/vertex_cover_search_trees.elisa` |
| Nim | `nim/v/vertex_cover_search_trees.nim` |
| Odin | `odin/v/vertex_cover_search_trees.odin` |
| Rust | `rust/v/vertex_cover_search_trees.rs` |
| V | `v/v/vertex_cover_search_trees.v` |
| Zig | `zig/v/vertex_cover_search_trees.zig` |

The primary exact-output oracle is `benchmarks/vertex_cover_search_trees_oracle.py`;
the independent verifier oracle uses exhaustive subset enumeration in
`benchmarks/vertex_cover_search_trees_verifier_oracle.py`.
