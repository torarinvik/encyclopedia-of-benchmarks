# Lexicographic breadth-first search

This package implements the LexBFS ordering described by the “LexBFS,
Structure, and Algorithms” entry. It starts at the supplied vertex, repeatedly
selects the unnumbered vertex with the lexicographically greatest sequence of
previously selected adjacent-vertex positions, and prepends the current
position to the labels of its unnumbered neighbors. Equal labels are resolved
by the lowest vertex ID.

## Contract

Input is `[node_count, edge_count, start_vertex, (u, v)...]`, where edges are
simple undirected pairs with `u < v`. Bounds are `1 <= node_count <= 16` and
`0 <= edge_count <= 120`. Output is the visitation order as little-endian
signed 64-bit vertex IDs. Invalid input returns `-1`; a null output or
insufficient capacity returns `-2` without writing.

The primary oracle compares explicit newest-first labels. The independent
verifier uses ordered partition refinement. The source permits any starting
vertex; explicit minimum-ID tie-breaking makes the profile reproducible.

## Source and clean-room status

The algorithm is the LexBFS of Rose, Tarjan, and Lueker, referenced by the
entry “LexBFS, Structure, and Algorithms,” DOI
[`10.1007/978-1-4939-2864-4_687`](https://doi.org/10.1007/978-1-4939-2864-4_687).
The ports and oracles are clean-room implementations; no book prose or
upstream source code is copied.

## Language ports

| Language | Source |
|---|---|
| C | `c/l/lex_bfs.c` |
| C3 | `c3/l/lex_bfs.c3` |
| C++ | `cpp/l/lex_bfs.cpp` |
| Elisa | `elisa/l/lex_bfs.elisa` |
| Nim | `nim/l/lex_bfs.nim` |
| Odin | `odin/l/lex_bfs.odin` |
| Rust | `rust/l/lex_bfs.rs` |
| V | `v/l/lex_bfs.v` |
| Zig | `zig/l/lex_bfs.zig` |
