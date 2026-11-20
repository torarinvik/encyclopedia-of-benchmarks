# Rotation-system planarity test

This bounded profile recognizes planarity by enumerating combinatorial
embeddings. For each connected component it tries every cyclic order of the
incident edges at each vertex. The orders determine face-boundary dart cycles;
a component is planar when some assignment has Euler characteristic
`V - E + F = 2`.

This tests whether an embedding exists. It differs from
[`planar_face_count`](../../p/planar_face_count/README.md), which counts the
faces of a supplied planar straight-line drawing, and from
[`upward_planarity_angle_assignment`](../../u/upward_planarity_angle_assignment/README.md),
which tests a bounded upward embedding with a supplied st-order.

## Contract

- Exported symbol: `rotation_system_planarity_test`; ABI: `i64_array_scalar`.
- Input: `[N, M, (u, v)*M]`; `1 <= N <= 6`, `0 <= M <= 15`.
- Each edge appears once as `0 <= u < v < N`; edge order is unrestricted.
  Loops, repeated edges, invalid endpoints, and malformed frames return `-1`.
- Output: `1` for planar, `0` for nonplanar, `-1` for invalid input.
- Maximum valid and parseable lengths are 32 and 33 signed 64-bit words.
- For `N >= 3`, the simple-planar bound rejects `M > 3*N-6` immediately.
  Connected components use the same bound with their own vertex and edge
  counts. Isolated vertices are planar.

## Search bound and references

Fix the least-ID neighbor as the start of each cyclic order, so a vertex of
degree `d` contributes `(d-1)!` choices when `d >= 2`, and one choice for
degree 0 or 1. After the planar edge-bound rejection, a searched component
has at most six vertices and twelve edges. It can have at most three degree-5
vertices: four such vertices would force the other two vertices to each have
degree at least four, requiring at least fourteen edges. Therefore the number
of cyclic-order assignments is at most
`24^3 * 6^3 = 1,990,656` per component. Each assignment traverses at most 24
darts.

The primary reference implements the componentwise rotation-system/Euler
search. Component roots and adjacency scans use ascending vertex ID; component
arrays retain BFS discovery order, and the mixed-radix rotation enumeration
carries from the last discovered vertex toward the first. Per-vertex tail
permutations use lexicographic order. The structurally independent reference checks for a `K5` or `K3,3`
minor using Wagner's characterization; at six vertices it enumerates the
possible five branch sets and the 3+3 bipartitions directly.

Sources: the [rotation principle and Euler formula](https://openresearch-repository.anu.edu.au/server/api/core/bitstreams/250c3d31-3080-41fe-a9ae-f5dd1ea7537c/content), the University of Illinois [dart successor and face-walk notes](https://jeffe.cs.illinois.edu/teaching/comptop/2023/notes/09-planar-graphs.html), and [Wagner's theorem](https://kam.mff.cuni.cz/~kyncl/tgg/ggt02.pdf). These are idea and theorem references only; the package is clean-room authored. See [`RIGHTS.md`](RIGHTS.md).

## Language ports

[C](../../../c/r/rotation_system_planarity_test.c) ·
[C3](../../../c3/r/rotation_system_planarity_test.c3) ·
[C++](../../../cpp/r/rotation_system_planarity_test.cpp) ·
[Elisa](../../../elisa/r/rotation_system_planarity_test.elisa) ·
[Mojo](../../../mojo/r/rotation_system_planarity_test.mojo) ·
[Nim](../../../nim/r/rotation_system_planarity_test.nim) ·
[Odin](../../../odin/r/rotation_system_planarity_test.odin) ·
[Rust](../../../rust/r/rotation_system_planarity_test.rs) ·
[V](../../../v/r/rotation_system_planarity_test.v) ·
[Zig](../../../zig/r/rotation_system_planarity_test.zig)

See [`workload.json`](workload.json), both reference implementations
([`primary_oracle.py`](primary_oracle.py) and
[`independent_oracle.py`](independent_oracle.py)), and the package-local
static inventory reviewer [`verify_workload.py`](verify_workload.py).
