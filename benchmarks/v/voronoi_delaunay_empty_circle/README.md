# Voronoi and Delaunay: bounded Delaunay graph

This package constructs the Delaunay graph by enumerating triples whose
circumcircles contain no other input site. The vertices are planar point sites;
two sites are adjacent when they share an empty-circle Delaunay triangle. Under
the profile's general-position constraints, this yields the unique Delaunay
triangulation graph. It is the dual adjacency structure of the corresponding
Voronoi regions.

Input is `[n,x_0,y_0,...]`, with `3 <= n <= 8` and integer coordinates in
`[-50,50]`. Duplicate points, collinear triples, and cocircular quadruples are
rejected so the triangulation is unique. The output is
`[edge_count,u_0,v_0,...]` with sorted zero-based undirected edge pairs. The
maximum output is 37 signed i64 values (296 bytes). Invalid input returns
`-1`; null output or insufficient capacity returns `-2` without writing.

The bounded implementation uses exact integer orientation and in-circle
determinants. It is a clean-room exhaustive empty-circle construction, not the
chapter's asymptotically faster sweep-line implementation; the output object
and general-position semantics are the Delaunay construction from the
chapter. Voronoi cell polygons are not emitted.

Source: “Voronoi Diagrams and Delaunay Triangulations,” *Encyclopedia of
Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_507`](https://doi.org/10.1007/978-1-4939-2864-4_507).
No chapter prose or source code is copied.

## Ports

| Language | Port |
|---|---|
| C | `c/v/voronoi_delaunay_empty_circle.c` |
| C3 | `c3/voronoi_delaunay_empty_circle.c3` |
| C++ | `cpp/v/voronoi_delaunay_empty_circle.cpp` |
| Elisa | `elisa/voronoi_delaunay_empty_circle.elisa` |
| Nim | `nim/v/voronoi_delaunay_empty_circle.nim` |
| Odin | `odin/v/voronoi_delaunay_empty_circle.odin` |
| Rust | `rust/v/voronoi_delaunay_empty_circle.rs` |
| V | `v/voronoi_delaunay_empty_circle.v` |
| Zig | `zig/v/voronoi_delaunay_empty_circle.zig` |

Primary oracle: `benchmarks/voronoi_delaunay_empty_circle_oracle.py`.
Independent verifier oracle: `benchmarks/voronoi_delaunay_empty_circle_verifier_oracle.py`.
