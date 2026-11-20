# Catmull–Clark subdivision

Perform one Catmull–Clark refinement step on a small closed polygon mesh in
two-dimensional coordinates. The step repositions each old vertex, inserts one
point per edge and face, and replaces every old face corner by a quadrilateral.
The result is the refined control mesh; the benchmark does not evaluate the
limit surface.

## Contract

The `float64_slice_io` input frame is
`[V,F,x_0,y_0,...,x_(V-1),y_(V-1), face_0,...,face_(F-1)]`. Each face record is
`[degree, vertex_id_0,...,vertex_id_(degree-1)]` in cyclic order. `V` is in
`0..=24`, `F` is in `0..=8`, and every coordinate is finite binary64. The only
empty mesh accepted is `V=F=0` with a two-value input. The maximum parseable
input length is 122 doubles.

Every nonempty face has degree 3 through 8, contains distinct vertex IDs in
`0..V-1`, and the complete variable-length frame must end exactly after the
last face. Each undirected edge must occur in exactly two faces. At every
vertex, the link made from the preceding and following vertex of each incident
face corner must be one connected cycle with at least three vertices. This
accepts disconnected closed components and does not require a globally
consistent orientation. Boundaries, repeated face vertices, isolated vertices,
nonmanifold edges, and pinched vertex links are invalid.

For a face, the new face point is the mean of its old vertices. An interior
edge point is the mean of its two endpoints and the two adjacent face points.
For an old vertex `P` of valence `n`, let `Fbar` be the mean of its adjacent
face points and `Rbar` the mean of its adjacent edge midpoints. The updated
point is `(Fbar + 2*Rbar + (n-3)*P)/n`. The ports use scaled weighted averages
to keep intermediate arithmetic finite for finite binary64 coordinates.

Output is a float64 array
`[V',F', coordinates..., quads...]`, where `V'=V+E+F` and `F'` is the sum of
the old face degrees. Coordinates are ordered as updated old vertices by ID,
edge points by lexicographic undirected endpoint pair, then face points by old
face ID. Quad indices follow original face order and corner order as
`[updated_vertex, next_edge_point, face_point, previous_edge_point]`. All
indices are zero-based integers exactly representable as binary64. The maximum
output length is 386 doubles. Success returns the number of doubles written;
malformed or nonmanifold input returns `-1`; a null output or insufficient
capacity for valid input returns `-2`. Input validation takes precedence and
errors leave output untouched.

The primary uses fixed edge-incidence tables and evaluates the Catmull–Clark
stencils in binary64. The independent reference reconstructs topology from
face-corner incidence and evaluates the same one-step geometry with exact
`Fraction` arithmetic before rounding each output coordinate to binary64. The
workload uses a tetrahedron with hand-pinned output, an empty mesh, and invalid
topology and ABI frames. The suite tolerance is `1e-12` absolute and relative.

## Source and overlap check

RosettaGit's public [task-title index](https://rosettagit.org/tasks/) supplied
the discovery title `Catmull–Clark subdivision surface`; no task page content,
examples, tests, submissions, or code was used. The method is defined by
Catmull and Clark's original paper, [“Recursively generated B-spline surfaces
on arbitrary topological meshes”](https://doi.org/10.1016/0010-4485(78)90110-0).
The independent formula description is Wolfram MathWorld's
[Catmull–Clark subdivision](https://mathworld.wolfram.com/Catmull-ClarkSubdivision.html).

The local [`delaunay_mesh_refinement`](../../d/delaunay_mesh_refinement/README.md)
changes a triangulation to satisfy geometric quality criteria; it is not a
polygon-surface subdivision scheme. [`polyhedron_volume`](../../p/polyhedron_volume/README.md)
measures signed volume of an oriented triangle mesh and does not refine it.
Neither package has the Catmull–Clark face, edge, and vertex rules.

See [`workload.json`](workload.json), [`RIGHTS.md`](RIGHTS.md),
[`INVENTORY.md`](INVENTORY.md), and the static [`check_inventory.py`](check_inventory.py).
The inventory helper has not been run.

## Ports

| Language | Source |
|---|---|
| C | [`c/c/catmull_clark_subdivision.c`](../../../c/c/catmull_clark_subdivision.c) |
| C3 | [`c3/c/catmull_clark_subdivision.c3`](../../../c3/c/catmull_clark_subdivision.c3) |
| C++ | [`cpp/c/catmull_clark_subdivision.cpp`](../../../cpp/c/catmull_clark_subdivision.cpp) |
| Elisa | [`elisa/c/catmull_clark_subdivision.elisa`](../../../elisa/c/catmull_clark_subdivision.elisa) |
| Mojo | [`mojo/c/catmull_clark_subdivision.mojo`](../../../mojo/c/catmull_clark_subdivision.mojo) |
| Nim | [`nim/c/catmull_clark_subdivision.nim`](../../../nim/c/catmull_clark_subdivision.nim) |
| Odin | [`odin/c/catmull_clark_subdivision.odin`](../../../odin/c/catmull_clark_subdivision.odin) |
| Rust | [`rust/c/catmull_clark_subdivision.rs`](../../../rust/c/catmull_clark_subdivision.rs) |
| V | [`v/c/catmull_clark_subdivision.v`](../../../v/c/catmull_clark_subdivision.v) |
| Zig | [`zig/c/catmull_clark_subdivision.zig`](../../../zig/c/catmull_clark_subdivision.zig) |
