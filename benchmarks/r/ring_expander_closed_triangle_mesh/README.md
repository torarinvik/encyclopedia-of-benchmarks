# Seeded Ring-Expander on a closed triangle mesh

This profile measures one pass of the Ring-Expander procedure described for
the LR mesh representation. It is distinct from the local Delaunay triangulation,
mesh-refinement, and triangulation point-location packages: those construct or
query triangulations, while this procedure grows a near-Hamiltonian edge ring
through the faces of a supplied mesh.

## Contract

Suite ABI: `i64_array_bytes_output`; exported symbol:
`ring_expander_closed_triangle_mesh`.

Input is `[n,t,s,face_vertices...]`, where `n` is the number of vertices,
`t` the number of triangles, `s` a corner ID, and the remaining `3*t` values
are oriented triangle triples in input order. Bounds are `4<=n<=12` and
`4<=t<=20`. Corner `3*i+j` is local vertex `j` of triangle `i`; local indices
are cyclic. The seed must satisfy `0<=s<3*t`.

A valid input is a connected, closed, consistently oriented simplicial
2-manifold. Every vertex ID is used; each face has three distinct vertices;
faces are unique; every undirected edge occurs in exactly two faces with
opposite directed orientations; and each vertex link is one connected cycle.
The explicit vertex-link check rejects pinched vertices even when every edge
has two incident faces. The connectedness check is by edge-adjacent triangles.
These conditions pin the paper's no-boundary manifold domain and make all
opposite-corner operations total.

For corner `c=3*i+j`, `c.n` is local index `(j+1) mod 3`, `c.p` is
`(j+2) mod 3`, and `c.o` is the corner opposite across the edge opposite `c`:
`o.n.v=c.p.v` and `o.p.v=c.n.v`. The derived right operator is `c.r=c.p.o`.
All IDs are zero-based. The operation initializes triangle and vertex marks to
false, sets `c=s`, then marks `s.n.v` and `s.p.v`. Each loop body records the
current corner in the trace; if `c.v` is unmarked it marks `c.v` and `c.t`,
otherwise if `c.t` is unmarked it replaces `c` with `c.o`. It then advances
with `c=c.r` and stops when the new corner equals the original `s.o`. This is
the paper's one-seed Ring-Expander pass. The paper's additional strategy of
repeating with random seeds and retaining the best ring is outside this
deterministic profile.

Output is little-endian signed-i64
`[trace_count, trace_corner_ids..., visited_vertex_mask, visited_triangle_mask]`.
The trace contains the corner at the start of each executed loop body, including
temporary backtracking states. It has at most `3*t` entries, as the paper states
that the traversal visits each corner at most once. The masks use bit `i` for
vertex or triangle ID `i`. The maximum valid input is 63 words; 64 words are
accepted by the parser only as a ceiling for rejecting a trailing value. The
maximum output is 504 bytes. Fixed workspace is capped at 8,192 bytes. A
conservative source-level account includes a 12x12x12 link table (1,728 bytes),
a 60-entry opposite-corner table (up to 480 bytes), a 12x12 edge-incidence
table (144 bytes), two 12x12 corner-index tables (1,152 bytes), a 480-byte face
buffer, a 480-byte staged trace, up to 108 bytes for a vertex-link queue/mark
pair, 180 bytes for the triangle queue/mark pair, 60 bytes for corner marks,
12 bytes for used-vertex marks, up to 480 bytes for a fixed-array face-argument
copy, and a 512-byte allowance for scalar state and serialization locals. This
totals at most 5,816 bytes, below the cap. The
edge-incidence/opposite-corner setup is O(t+v^2); dense vertex-link degree and
connectivity checks are O(v^3), and the Ring-Expander walk itself is O(t)
because it visits each corner at most once. Malformed input returns `-1`.
Valid input with a null output or insufficient capacity returns `-2`;
validation precedes output-capacity handling, and failures write no bytes.

## Sources and duplicate decision

The supplied *Encyclopedia of Algorithms*, Chapter 589, “Triangulation Data
Structures,” illustrates the Ring-Expander/corner-table representation. The
operational traversal and the closed-manifold precondition are pinned to
Topraj Gurung, Mark Luffel, Peter Lindstrom, and Jarek Rossignac, “LR: Compact
Connectivity Representation for Triangle Meshes,” *ACM Transactions on
Graphics* 30(4), Article 67 (2011), §4.2, DOI
[10.1145/1964921.1964962](https://doi.org/10.1145/1964921.1964962). The paper
defines the core and derived corner operators and gives the exact greedy
traversal. The bounded profile supplies the seed instead of drawing it
randomly. The profile measures no seed-selection expectation.

The primary reference constructs an opposite-corner table from directed edge
incidences and then follows the corner operators. The independent reference
scans all face edges when resolving each opposite corner, then validates the
vertex links and connected face graph through those matches. Its opposite
corner resolution is O(t^2), intentionally unlike the native incidence table.
Both are clean-room references; no paper code, prose, mesh, or test fixture is
copied.
See [RIGHTS.md](RIGHTS.md) for provenance.

## Package files

- Workload: [workload.json](workload.json)
- Inventory: [INVENTORY.md](INVENTORY.md) and [INVENTORY.json](INVENTORY.json)
- Static helpers: [check_inventory.py](check_inventory.py),
  [verify_workload.py](verify_workload.py)
- Primary oracle: [ring_expander_closed_triangle_mesh_oracle.py](../../ring_expander_closed_triangle_mesh_oracle.py)
- Independent oracle: [ring_expander_closed_triangle_mesh_verifier_oracle.py](../../ring_expander_closed_triangle_mesh_verifier_oracle.py)

| Language | Source |
|---|---|
| C | `c/r/ring_expander_closed_triangle_mesh.c` |
| C3 | `c3/r/ring_expander_closed_triangle_mesh.c3` |
| C++ | `cpp/r/ring_expander_closed_triangle_mesh.cpp` |
| Elisa | `elisa/r/ring_expander_closed_triangle_mesh.elisa` |
| Mojo | `mojo/r/ring_expander_closed_triangle_mesh.mojo` |
| Nim | `nim/r/ring_expander_closed_triangle_mesh.nim` |
| Odin | `odin/r/ring_expander_closed_triangle_mesh.odin` |
| Rust | `rust/r/ring_expander_closed_triangle_mesh.rs` |
| V | `v/r/ring_expander_closed_triangle_mesh.v` |
| Zig | `zig/r/ring_expander_closed_triangle_mesh.zig` |

The package is registered in the `i64_array_bytes_output` runner and verifier,
the catalog, and the Chapter 589 crosswalk. No programs, tests, scripts,
checkers, builds, compilers, profilers, or benchmarks were run.
