# SCC condensation DAG

This profile constructs the condensation graph of a bounded directed graph.
It first finds the strongly connected components, then replaces every
inter-component edge with a directed edge between the corresponding quotient
vertices. Edges inside one component disappear; duplicate quotient edges are
collapsed.

## Contract

Input is `[vertex_count,edge_count,(source,target)*edge_count]`, with
`0<=vertex_count<=8`, `0<=edge_count<=28`, and zero-based endpoints. Self-loops
and repeated input edges are allowed. Output bytes are
`[component_count,component_id[0..vertex_count),row_mask[0..component_count)]`.
Components are numbered by ascending minimum vertex. Row `i` sets bit `j` iff
some input edge goes from component `i` to component `j`; diagonal bits are
always clear. The empty graph emits `[0]`. Malformed input returns `-1`; a
null or undersized output returns `-2` without writing bytes. Maximum output is
17 bytes.

The primary uses Kosaraju's two-pass procedure and constructs the quotient from
the original edges. The independent reference groups vertices by mutual
reachability and derives the quotient directly. The bounded primary uses
`O(V^2+E)` work; the independent reference uses `O(V^3+E)`.

This adds the quotient-DAG operation described as an optional final step in
CP-Algorithms' [SCC and condensation graph article](https://cp-algorithms.com/graph/strongly-connected-components.html).
Local [`kosaraju`](../../k/kosaraju/README.md),
[`tarjan_scc`](../../t/tarjan_scc/README.md), and
[`gabow_scc`](../gabow_scc/README.md) profiles return SCC partitions but do not
construct the condensation edges. The source article is under CC BY-SA 4.0;
this package uses its algorithm description only. Implementations, references,
contract, fixtures, and prose are clean-room work. See [`RIGHTS.md`](RIGHTS.md).

## Inventory

[`verify_workload.py`](verify_workload.py) statically checks the bounded
workload, both references, required fixtures, and the ten exported source
files. It never compiles or executes the ports.

| Language | Source |
|---|---|
| C | [`c/g/scc_condensation_dag.c`](../../../c/g/scc_condensation_dag.c) |
| C3 | [`c3/g/scc_condensation_dag.c3`](../../../c3/g/scc_condensation_dag.c3) |
| C++ | [`cpp/g/scc_condensation_dag.cpp`](../../../cpp/g/scc_condensation_dag.cpp) |
| Elisa | [`elisa/g/scc_condensation_dag.elisa`](../../../elisa/g/scc_condensation_dag.elisa) |
| Mojo | [`mojo/g/scc_condensation_dag.mojo`](../../../mojo/g/scc_condensation_dag.mojo) |
| Nim | [`nim/g/scc_condensation_dag.nim`](../../../nim/g/scc_condensation_dag.nim) |
| Odin | [`odin/g/scc_condensation_dag.odin`](../../../odin/g/scc_condensation_dag.odin) |
| Rust | [`rust/g/scc_condensation_dag.rs`](../../../rust/g/scc_condensation_dag.rs) |
| V | [`v/g/scc_condensation_dag.v`](../../../v/g/scc_condensation_dag.v) |
| Zig | [`zig/g/scc_condensation_dag.zig`](../../../zig/g/scc_condensation_dag.zig) |
