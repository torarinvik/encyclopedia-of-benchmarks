# DAG transitive reduction

This profile returns the number of arcs in the unique transitive reduction of
a bounded directed acyclic graph. It removes every input arc whose endpoints
remain connected by another directed path after that arc is deleted.

The primary reference computes non-reflexive Boolean transitive closure and
retains `u -> v` only when no distinct intermediate vertex `w` satisfies
`u -> w` and `w` reaches `v`. The independent reference removes each edge in
turn and runs a graph search from its tail to its head. The two references use
different reduction tests and graph representations.

This measures reduction of a DAG's reachability relation. It is distinct from
[`transitive_closure_reflexive_matrix`](../../t/transitive_closure_reflexive_matrix/README.md),
which constructs a reflexive closure matrix, and from
[`topological_sort`](../../t/topological_sort/README.md), which only returns a
vertex order.

## Contract

- Exported symbol: `dag_transitive_reduction`; ABI: `i64_array_scalar`.
- Input: `[N, M, (tail, head)*M]`, with `1 <= N <= 8` and `0 <= M <= 28`.
- The input must be a simple directed acyclic graph. Vertex IDs are arbitrary;
  arcs need not follow numeric order. Loops, repeated ordered arcs, invalid
  endpoints, cycles, malformed frames, null input, and trailing words return
  `-1`.
- Output is the number of cover arcs retained in the unique transitive
  reduction, from `0` through `28`.
- Exact input length is `2 + 2*M`; maximum valid and parseable lengths are 58
  and 59 signed 64-bit words.
- Vertex, middle, and edge scans use ascending IDs and input order. Only a
  scalar count is returned, so equivalent traversal ties do not affect output.

The mathematical source is Aho, Garey, and Ullman, [“The Transitive Reduction
of a Directed Graph”](https://doi.org/10.1137/0201008). See
[`RIGHTS.md`](RIGHTS.md) for provenance.

## Language ports

[C](../../../c/d/dag_transitive_reduction.c) ·
[C3](../../../c3/d/dag_transitive_reduction.c3) ·
[C++](../../../cpp/d/dag_transitive_reduction.cpp) ·
[Elisa](../../../elisa/d/dag_transitive_reduction.elisa) ·
[Mojo](../../../mojo/d/dag_transitive_reduction.mojo) ·
[Nim](../../../nim/d/dag_transitive_reduction.nim) ·
[Odin](../../../odin/d/dag_transitive_reduction.odin) ·
[Rust](../../../rust/d/dag_transitive_reduction.rs) ·
[V](../../../v/d/dag_transitive_reduction.v) ·
[Zig](../../../zig/d/dag_transitive_reduction.zig)

See [`workload.json`](workload.json), the [closure-based primary
reference](primary_oracle.py), the [edge-deletion BFS reference](independent_oracle.py),
and the package-local static inventory reviewer [`verify_workload.py`](verify_workload.py).
