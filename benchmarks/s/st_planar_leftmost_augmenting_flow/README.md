# st-planar leftmost augmenting flow

This bounded profile captures the chapter's st-planar maximum-flow special case.
It repeatedly finds a residual source-to-sink path by depth-first search, using
per-vertex supplied cyclic rotations as the left-first adjacency order, then
augments by the path bottleneck. The profile fixes the start of each cyclic
rotation at its first listed edge to resolve ties deterministically. It reports
the maximum-flow value only; it does not serialize per-edge flow assignments.

Input is signed i64 words:

```text
[n,m,s,t, (u,v,capacity)*m, (degree,edge_id...)*n]
```

Vertices and edge IDs are zero-based. Each directed edge is `(tail,head,capacity)`.
The underlying undirected graph is connected and simple; capacities are integers
in `[0,5]`. Each per-vertex rotation lists all incident edge IDs exactly once.
The input promise is a valid combinatorial planar embedding with `s` and `t` on
a common outer face; the face promise is not reconstructed from coordinates.
This profile accepts `2<=n<=6`, `1<=m<=10`, and at most 60 input words. Its
left-first DFS ordering is a deterministic bounded refinement of the chapter's
leftmost augmenting-path rule. General directed planar flow when `s,t` do not
share a face, the dual shortest-path initialization, and Reif's undirected
min-cut algorithm remain outside this profile.

Output is one little-endian signed i64 word `[maximum_flow_value]` (8 bytes).
Malformed framing or graph data returns `-1`; null output or capacity below 8
returns `-2` without writing. Fixed workspace is 4096 bytes. The primary oracle
uses exhaustive source/sink cut enumeration; the independent verifier uses
Edmonds–Karp, so neither replays the measured DFS trace.

Source: Glencora Borradaile, “Planar Maximum s-t Flow,” *Encyclopedia of
Algorithms*, DOI `10.1007/978-1-4939-2864-4_626`, EPUB `OEBPS/AChap626.html`,
section “st-Planar Graphs.” The chapter describes far-left augmenting paths and
at-most-|E| saturations for the st-planar case. It gives no source-code license;
these ports are clean-room implementations of the bounded path-selection and
bottleneck-augmentation profile.

| Language | Port |
|---|---|
| C | `c/s/st_planar_leftmost_augmenting_flow.c` |
| C++ | `cpp/s/st_planar_leftmost_augmenting_flow.cpp` |
| Rust | `rust/s/st_planar_leftmost_augmenting_flow.rs` |
| Nim | `nim/s/st_planar_leftmost_augmenting_flow.nim` |
| Odin | `odin/s/st_planar_leftmost_augmenting_flow.odin` |
| Zig | `zig/s/st_planar_leftmost_augmenting_flow.zig` |
| V | `v/s/st_planar_leftmost_augmenting_flow.v` |
| C3 | `c3/s/st_planar_leftmost_augmenting_flow.c3` |
| Elisa | `elisa/s/st_planar_leftmost_augmenting_flow.elisa` |
