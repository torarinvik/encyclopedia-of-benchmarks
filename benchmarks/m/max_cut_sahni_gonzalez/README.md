# Sahni–Gonzalez deterministic Max-Cut approximation

This package profiles the deterministic half-approximation described in the
“Max Cut” entry. Vertices are processed by increasing ID. For each vertex, the
algorithm compares the weight of edges that would cross to already assigned
vertices on either side and chooses the side with the larger incremental cut.
Ties go to side 0. The result contains the cut weight and one side label per
vertex.

## Contract

Input is `[node_count, edge_count, (u, v, weight)...]` with simple undirected
edges listed once in canonical order (`u < v`) and nonnegative integer weights.
Bounds are `1 <= node_count <= 16`, `0 <= edge_count <= 120`, and each weight
is at most 10,000. Output is `[cut_weight, side_0, ..., side_(n-1)]` as
little-endian signed i64 values, with side labels in `{0,1}`. Invalid input
returns `-1`; null output or insufficient capacity returns `-2` without
writing.

The greedy approximation guarantees a cut of at least half the total edge
weight. A deterministic vertex order and tie rule make the profile repeatable.

## Source and clean-room status

The profile uses the Sahni–Gonzalez deterministic half-approximation
discussed in the “Max Cut” entry, DOI
[`10.1007/978-1-4939-2864-4_219`](https://doi.org/10.1007/978-1-4939-2864-4_219).
All implementations are clean-room; the book is used only to identify the
algorithm and no book prose or upstream source code is copied.

## Language ports

| Language | Source |
|---|---|
| C | `c/m/max_cut_sahni_gonzalez.c` |
| C3 | `c3/m/max_cut_sahni_gonzalez.c3` |
| C++ | `cpp/m/max_cut_sahni_gonzalez.cpp` |
| Elisa | `elisa/m/max_cut_sahni_gonzalez.elisa` |
| Nim | `nim/m/max_cut_sahni_gonzalez.nim` |
| Odin | `odin/m/max_cut_sahni_gonzalez.odin` |
| Rust | `rust/m/max_cut_sahni_gonzalez.rs` |
| V | `v/m/max_cut_sahni_gonzalez.v` |
| Zig | `zig/m/max_cut_sahni_gonzalez.zig` |
