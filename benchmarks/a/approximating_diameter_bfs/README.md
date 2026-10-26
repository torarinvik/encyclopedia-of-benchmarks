# Diameter approximation by one BFS

This profile implements the deterministic 2-approximation stated in Chapter
566: run breadth-first search from an arbitrary vertex and return its
eccentricity. The profile fixes that vertex to ID 0. For any connected
undirected unweighted graph, the eccentricity is at most the diameter and at
least half the diameter, so it is a factor-2 estimate.

## Contract

ABI: `i64_array_bytes_output`; symbol `approximating_diameter_bfs`. Input is
`[vertex_count,edge_count,(u,v)...]` for a connected simple undirected graph,
with canonical endpoints `0 <= u < v < vertex_count`. The graph has 1–16
vertices and at most 120 edges. Output is one little-endian signed 64-bit
word: the distance from vertex 0 to the farthest vertex. Invalid framing,
duplicate edges, or a disconnected graph returns `-1`; null or short output
returns `-2` without writes. The maximum input is 242 words and output is
8 bytes.

This is distinct from exact all-pairs/diameter packages, which compute the
full diameter. It preserves the chapter’s arbitrary-root BFS estimate and
its 2-approximation guarantee; it does not implement the chapter’s faster
subcubic Aingworth or later landmark algorithms.

## Source attribution and rights

Based on Liam Roditty, “Approximating the Diameter,” *Encyclopedia of
Algorithms*, DOI
[10.1007/978-1-4939-2864-4_566](https://doi.org/10.1007/978-1-4939-2864-4_566).
The ports independently implement the BFS profile. No book prose, code, or
figures are reproduced. Springer retains copyright to the book; attribution
does not grant redistribution rights to its contents.

Primary oracle: [`approximating_diameter_bfs_oracle.py`](../../approximating_diameter_bfs_oracle.py).
Independent verifier: [`approximating_diameter_bfs_verifier_oracle.py`](../../approximating_diameter_bfs_verifier_oracle.py).

| Language | Source |
|---|---|
| C | [`c/a/approximating_diameter_bfs.c`](../../../c/a/approximating_diameter_bfs.c) |
| C3 | [`c3/a/approximating_diameter_bfs.c3`](../../../c3/a/approximating_diameter_bfs.c3) |
| C++ | [`cpp/a/approximating_diameter_bfs.cpp`](../../../cpp/a/approximating_diameter_bfs.cpp) |
| Elisa | [`elisa/a/approximating_diameter_bfs.elisa`](../../../elisa/a/approximating_diameter_bfs.elisa) |
| Nim | [`nim/a/approximating_diameter_bfs.nim`](../../../nim/a/approximating_diameter_bfs.nim) |
| Odin | [`odin/a/approximating_diameter_bfs.odin`](../../../odin/a/approximating_diameter_bfs.odin) |
| Rust | [`rust/a/approximating_diameter_bfs.rs`](../../../rust/a/approximating_diameter_bfs.rs) |
| V | [`v/a/approximating_diameter_bfs.v`](../../../v/a/approximating_diameter_bfs.v) |
| Zig | [`zig/a/approximating_diameter_bfs.zig`](../../../zig/a/approximating_diameter_bfs.zig) |
