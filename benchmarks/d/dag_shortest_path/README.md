# DAG shortest path

Find the minimum path weight from one source vertex to one target vertex in a
weighted directed acyclic graph. The primary obtains a topological order with
Kahn's indegree queue and relaxes each edge once in that order. Signed edge
weights are supported because a DAG has no cycles that could make a negative
cycle or invalidate the one-pass recurrence. The independent reference
enumerates every source-to-target path after a separate transitive-closure
cycle check.

## Contract

The `i64_array_scalar` input is
`[vertex_count,edge_count,source,target,(from,to,weight)*edge_count]`.
There are 1–12 vertices and 0–66 edges. Edges form a simple directed graph:
self-loops and duplicate ordered pairs are invalid, and the full graph must be
acyclic. Each signed weight is between -1000 and 1000. Input length must be
exactly `4+3*edge_count`; malformed or cyclic input returns `-1`.

A reachable target returns `100000 + shortest_distance`; an unreachable target
returns zero. The distance offset makes the small signed distance range
unambiguous from the zero unreachable marker and the negative invalid marker.
The maximum valid and parseable input lengths are 202 and 203 words. Topological
sorting and edge-list scans take `O(VE+V)` time in this bounded profile and
`O(V+E)` space; the independent exhaustive path reference can enumerate
`O(2^V)` paths in a dense DAG.

The source profile comes from the [CLRS-30 inventory](https://github.com/google-deepmind/clrs/blob/master/README.md), which includes single-source shortest paths in a DAG. The implementations, contract, and fixtures are clean-room. The CLRS repository is Apache-2.0; this package uses its algorithm description only. See [`RIGHTS.md`](RIGHTS.md).

See [`workload.json`](workload.json), [`primary_oracle.py`](primary_oracle.py),
[`independent_oracle.py`](independent_oracle.py), and
[`verify_workload.py`](verify_workload.py).

| Language | Source |
|---|---|
| C | [c/d/dag_shortest_path.c](../../../c/dag_shortest_path.c) |
| C3 | [c3/d/dag_shortest_path.c3](../../../c3/dag_shortest_path.c3) |
| C++ | [cpp/d/dag_shortest_path.cpp](../../../cpp/dag_shortest_path.cpp) |
| Elisa | [elisa/d/dag_shortest_path.elisa](../../../elisa/dag_shortest_path.elisa) |
| Mojo | [mojo/d/dag_shortest_path.mojo](../../../mojo/dag_shortest_path.mojo) |
| Nim | [nim/d/dag_shortest_path.nim](../../../nim/d/dag_shortest_path.nim) |
| Odin | [odin/d/dag_shortest_path.odin](../../../odin/dag_shortest_path.odin) |
| Rust | [rust/d/dag_shortest_path.rs](../../../rust/dag_shortest_path.rs) |
| V | [v/d/dag_shortest_path.v](../../../v/dag_shortest_path.v) |
| Zig | [zig/d/dag_shortest_path.zig](../../../zig/dag_shortest_path.zig) |
