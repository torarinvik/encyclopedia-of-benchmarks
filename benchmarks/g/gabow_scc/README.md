# Gabow path-based strongly connected components

This benchmark implements Harold N. Gabow's one-pass path-based strongly
connected component method, described in “Path-based depth-first search for
strong and biconnected components,” *Information Processing Letters* 74
(2000), 107–114. The original publication is available at the
[DOI](https://doi.org/10.1016/S0020-0190(00)00051-X) and in an
[author-hosted copy](https://www.cs.princeton.edu/courses/archive/spr09/cos423/Lectures/bi-gabow.pdf).
The source description is used for algorithm attribution; the ten ports and
two Python oracles are independently written clean-room implementations.

## Contract

Input is `[vertex_count, edge_count, (source,target)*edge_count]`, with
zero-based vertices, `0<=vertex_count<=40`, and `0<=edge_count<=2047`. The
input length must be exactly `2+2*edge_count`. Self-loops are allowed and
repeated directed edges are coalesced. Every declared vertex is included,
including isolates.

The implementation stores each vertex's unique neighbors in a bounded
adjacency list. An iterative depth-first traversal assigns preorder numbers,
keeps unresolved vertices on stack `S`, and keeps candidate component roots on
stack `P`. When an edge reaches a discovered vertex that is still unassigned,
later candidate boundaries are removed from `P`. When a vertex finishes as
the top boundary, the suffix of `S` through that vertex is emitted as one
component. Each vertex and unique edge is processed a bounded number of times
by the SCC traversal, which takes `O(V+E)` time. Canonical component ordering
and serialization use bounded `O(V^2)` scans, so the complete call takes
`O(V^2+E)` time and uses `O(V+E)` storage at the declared bounds.

Output is `[component_count, (component_size, sorted_vertex_ids...)*]`, with
one unsigned byte per value. Components are ordered lexicographically by their
sorted vertex lists. Since components are disjoint, this is the same as
ordering by their smallest vertex. The empty graph encodes as `[0]`; the
maximum output is 81 bytes. A malformed input returns `-1`. A null or
undersized output returns `-2` without modifying output. The maximum local
workspace is 2001 scalar elements, including the staged byte result.

The path-based procedure is distinct from local `tarjan_scc` low-link updates
and local `kosaraju`'s two-pass transpose traversal. The primary independent
oracle groups vertices by mutual reachability; the verifier uses the
two-pass Kosaraju method:
[`gabow_scc_oracle.py`](../../gabow_scc_oracle.py) and
[`gabow_scc_kosaraju_oracle.py`](../../gabow_scc_kosaraju_oracle.py).
`workload.json` records fixtures, encoding, source, and bounds. The
package-local `verify_gabow_scc_package.py` is a static inventory and fixture
consistency checker.

## Language ports

- [`c/g/gabow_scc.c`](../../../c/g/gabow_scc.c)
- [`c3/g/gabow_scc.c3`](../../../c3/g/gabow_scc.c3)
- [`cpp/g/gabow_scc.cpp`](../../../cpp/g/gabow_scc.cpp)
- [`elisa/g/gabow_scc.elisa`](../../../elisa/g/gabow_scc.elisa)
- [`mojo/g/gabow_scc.mojo`](../../../mojo/g/gabow_scc.mojo)
- [`nim/g/gabow_scc.nim`](../../../nim/g/gabow_scc.nim)
- [`odin/g/gabow_scc.odin`](../../../odin/g/gabow_scc.odin)
- [`rust/g/gabow_scc.rs`](../../../rust/g/gabow_scc.rs)
- [`v/g/gabow_scc.v`](../../../v/g/gabow_scc.v)
- [`zig/g/gabow_scc.zig`](../../../zig/g/gabow_scc.zig)
