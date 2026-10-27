# Fixed-embedding upward-planarity angle assignment

This package implements the flow formulation described in DOI 653 for testing
whether a supplied connected plane digraph has an embedding-preserving upward
planar drawing, and returns one upward-consistent angle assignment when it
does. It does not construct drawing coordinates.

Input is `[n,m,f,outer,edges...,face_walks...]`. Vertices are `0..n-1`; the
`m` directed arcs are simple, sorted by `(tail,head)`. Each face record is
`[walk_length,(from,to)[walk_length]]`; face walks are closed traversal walks
of the undirected embedding, and every directed traversal of every underlying
edge appears exactly once. The input must describe a connected plane embedding
(`n-m+f=2`), an acyclic digraph, and a bimodal rotation system. The profile
limits `2<=n<=8`, `1<=m<=18`, and `1<=f<=12`.

For each face, the ports count source-switch and sink-switch angles from the
actual arc directions. A face capacity is `(S+T)/2-1` for an internal face
and `(S+T)/2+1` for the designated outer face. A terminal vertex (source or
sink) supplies one unit; each face demands its capacity; an incidence arc
exists when the terminal appears on the face boundary. To make a feasible
witness canonical, terminals are processed by vertex ID and each takes the
smallest incident face that leaves the remaining instance feasible. Residual
feasibility is checked by an augmenting-path matcher. Thus the face-ID vector
is lexicographically smallest in terminal order. If feasible, output is `[1,r,(vertex,face,corner_index)*]`
in ascending terminal vertex order. `corner_index` is the first matching
boundary corner in that face walk. If infeasible, output is `[0,r,(-1,-1,-1)*]`.

ABI: `i64_array_bytes_output`, symbol `upward_planarity_angle_assignment`.
Malformed framing, a disconnected/nonplanar face system, a directed cycle, or
a non-bimodal embedding returns `-1`. Null output or insufficient capacity
returns `-2` without writing. Maximum input is 124 i64 words; maximum output
is 26 i64 words (208 bytes). The profile covers only the chapter's
fixed-embedding feasibility/angle-assignment procedure. It does not search
for an embedding, implement the variable-embedding NP-hard problem, augment
to an st-planar graph, or compute drawing coordinates.

The primary oracle greedily fixes the lexicographically smallest feasible
face choice using residual matching checks. The independent verifier
enumerates complete terminal-to-face assignments in lexicographic order.

Source: Walter Didimo, “Upward Graph Drawing,” *Encyclopedia of Algorithms*,
DOI 10.1007/978-1-4939-2864-4_653. See [`RIGHTS.md`](RIGHTS.md).

| Language | Port |
|---|---|
| C | `c/u/upward_planarity_angle_assignment.c` |
| C3 | `c3/u/upward_planarity_angle_assignment.c3` |
| C++ | `cpp/u/upward_planarity_angle_assignment.cpp` |
| Elisa | `elisa/u/upward_planarity_angle_assignment.elisa` |
| Nim | `nim/u/upward_planarity_angle_assignment.nim` |
| Odin | `odin/u/upward_planarity_angle_assignment.odin` |
| Rust | `rust/u/upward_planarity_angle_assignment.rs` |
| V | `v/u/upward_planarity_angle_assignment.v` |
| Zig | `zig/u/upward_planarity_angle_assignment.zig` |
