# Triangle-mesh faces from an edge graph

This package is a bounded deterministic replay of a topological heuristic for
recovering nonoriented triangle faces from an undirected edge set. It profiles
candidate-triangle generation, edge-incidence propagation, and the source
paper's minimum-incidence fallback.

## Contract

- ABI: `i64_array_bytes_output`; symbol:
  `triangle_mesh_faces_from_edge_graph`.
- Input is `[vertex_count, edge_count, (u, v)*edge_count]` with 3–8 vertices
  labeled `0..vertex_count-1` and 0–28 undirected edges. Edges must be simple:
  no self-loops or repeated endpoint pairs. Input endpoint order does not
  affect the result.
- A candidate face is every 3-cycle `(a,b,c)` with `a<b<c`, generated in
  lexicographic order.
- First, choose the lexicographically first remaining triangle containing a
  degree-three graph vertex, repeating until none remain. Next, an edge forces
  its remaining incident candidates when their count equals `2-used_count`.
  Choose the first active triangle touching any forced edge and recompute.
- If candidates remain and no edge is forced, choose the triangle minimizing
  the sum of its current active incidences on the three edges. Ties use
  lexicographic order. This determinization and the lexicographic seed order
  are benchmark-profile conventions.
- Selecting a face increments each edge use. Once an edge reaches two uses,
  other active candidates containing it are removed.
- Output is `[status, face_count, (a,b,c)*face_count]` as little-endian signed
  i64 words. Faces appear in selection order. Status bit 0 records whether the
  fallback was used; status bit 1 is clear only when at least one edge was
  supplied and every supplied edge has exactly two selected incidences. Thus
  0/1 mean complete edge coverage and 2/3 mean incomplete edge coverage, with
  the low bit indicating fallback. The empty edge set is intentionally
  incomplete (status 2), rather than vacuously complete.
- Invalid input returns `-1`. Null or short output returns `-2` without
  writes, after input validation. The maximum candidate set has 56 triangles;
  the output frame is bounded at 1,360 bytes. Workspace is 8,192 bytes.

The status describes the heuristic's edge-use outcome. It does not certify
that an arbitrary graph is a mesh or that selected triangles reconstruct a
correct surface. The cited paper itself describes the fallback as heuristic
and notes that it can fail on some inputs. The package makes no general
reconstruction guarantee.

## References and local distinction

The primary uses an incremental candidate-incidence table. The independent
reference recomputes all active edge incidences and triangle scores on each
transition. Both preserve the same frozen deterministic rules.

The local mesh packages cover supplied-face operations such as subdivision,
volume, or geometric measurements. None reconstructs triangle faces from an
edge-only graph; this is a separate topology-inference kernel.

Method source: Marek Zabran, “An Algorithm Recreating 3D Triangle Mesh Faces
from Its Edges,” CESCG 2018 ([paper PDF](https://cescg.org/wp-content/uploads/2018/04/Zabran-An-Algorithm-Recreating-3D-Triangle-Mesh-Faces-from-Its-Edges.pdf)).
The paper is a non-peer-reviewed proceedings paper. The pinned RosettaCodeData
[popular-title index](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks)
is cited for title discovery only; no task prose, submitted code, examples, or
tests were reused. See [RIGHTS.md](RIGHTS.md).

The hand-pinned [workload](workload.json) covers empty, tetrahedral, and
fallback cases, malformed frames, and output errors. Package files and all
ten native ports are listed in [INVENTORY.md](INVENTORY.md) and
[`inventory.json`](inventory.json). Helpers are authored but have not been
run.

| Language | Source |
|---|---|
| C | [c/f/triangle_mesh_faces_from_edge_graph.c](../../../c/f/triangle_mesh_faces_from_edge_graph.c) |
| C3 | [c3/f/triangle_mesh_faces_from_edge_graph.c3](../../../c3/f/triangle_mesh_faces_from_edge_graph.c3) |
| C++ | [cpp/f/triangle_mesh_faces_from_edge_graph.cpp](../../../cpp/f/triangle_mesh_faces_from_edge_graph.cpp) |
| Elisa | [elisa/f/triangle_mesh_faces_from_edge_graph.elisa](../../../elisa/f/triangle_mesh_faces_from_edge_graph.elisa) |
| Mojo | [mojo/f/triangle_mesh_faces_from_edge_graph.mojo](../../../mojo/f/triangle_mesh_faces_from_edge_graph.mojo) |
| Nim | [nim/f/triangle_mesh_faces_from_edge_graph.nim](../../../nim/f/triangle_mesh_faces_from_edge_graph.nim) |
| Odin | [odin/f/triangle_mesh_faces_from_edge_graph.odin](../../../odin/f/triangle_mesh_faces_from_edge_graph.odin) |
| Rust | [rust/f/triangle_mesh_faces_from_edge_graph.rs](../../../rust/f/triangle_mesh_faces_from_edge_graph.rs) |
| V | [v/f/triangle_mesh_faces_from_edge_graph.v](../../../v/f/triangle_mesh_faces_from_edge_graph.v) |
| Zig | [zig/f/triangle_mesh_faces_from_edge_graph.zig](../../../zig/f/triangle_mesh_faces_from_edge_graph.zig) |
