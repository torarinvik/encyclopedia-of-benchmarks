# Offline dynamic bipartiteness

This package answers whole-graph bipartiteness queries for a known trace of
undirected edge additions and removals. It places each edge's active time
interval into a segment tree over event indices, then traverses that tree with
a rollback parity DSU. Each inserted edge adds the constraint
`color[u] XOR color[v] = 1`; the DSU counts constraints that contradict an
already connected pair. A query returns `1` exactly when that count is zero.

## Contract

The ABI is `i64_array_bytes_output` with exported symbol
`offline_dynamic_bipartiteness`. Input is
`[n,q,(op,a,b,c)*q]`, with `1<=n<=16`, `0<=q<=64`, and exact length
`2+4*q` signed 64-bit words. Vertex IDs are zero-based.

- Add `[0,id,u,v]` inserts undirected edge `{u,v}`. IDs are `0..63` and may
  appear in an add only once in the trace. Endpoints must be canonical
  (`0<=u<=v<n`). A self-loop is valid and makes the graph non-bipartite while
  active. Parallel edges are disallowed while an equal endpoint pair is
  already active; the same pair may be added again with a fresh ID after
  removal.
- Remove `[1,id,0,0]` requires that ID to be active and removes its edge before
  later events. The active interval is half-open: `[add_event, remove_event)`;
  an edge without a removal stays active to the end of the trace.
- Query `[2,0,0,0]` asks whether the entire graph after preceding updates is
  bipartite. All three reserved fields must be zero.

Output is one little-endian signed 64-bit `0` or `1` per query, in event order.
A trace without queries returns zero bytes. Malformed input returns `-1`.
Null output or insufficient output capacity returns `-2` without writes, and
input validation takes precedence. The maximum valid and parseable input
lengths are 258 and 259 words; output is at most 512 bytes.

The interval decomposition stores at most 64 edge IDs per segment-tree node.
Along any root-to-leaf path, at most 64 active edge constraints enter the
rollback history. The explicit fixed-array payload is 143,936 bytes for
64-bit `size_t`/`usize`/`int` tables; the declared workspace cap is 196,608
bytes, including bounded recursion frames and call-local state. Input
validation and removal lookup take `O(q^2)` work at these small limits. Each
edge interval contributes `O(log q)` segment entries, and parity-DSU finds
take `O(log n)` worst-case time under union by size without path compression.

## References and distinction

The primary [oracle](../../offline_dynamic_bipartiteness_oracle.py) uses the
same interval-over-time and rollback-parity state structure. The independent
[BFS reference](independent_bfs_reference.py) rebuilds the active adjacency
list and colors every component at each query. It does not use a segment
tree or DSU.

Local [`offline_dynamic_connectivity`](../offline_dynamic_connectivity/README.md)
answers connectivity with rollback DSU but has no parity invariant or odd-cycle
state. [`online_bipartiteness_dsu`](../online_bipartiteness_dsu/README.md)
stores parity for insertion-only traces and cannot process deletions. This
package measures the combined offline interval and rollback parity procedure.

The OI Wiki [segment-tree offline-query article](https://oi-wiki.org/topic/segment-tree-offline/)
describes time-interval assignment with rollback DSU. Its [DSU article](https://oi-wiki.org/ds/dsu/)
describes parity constraints and DSU bipartiteness checks. The bounded event
format and limits here are repository-defined. Ports, references, workload,
and documentation are clean-room; only algorithm descriptions are used.

| Language | Port |
|---|---|
| C | [`c/o/offline_dynamic_bipartiteness.c`](../../../c/o/offline_dynamic_bipartiteness.c) |
| C3 | [`c3/o/offline_dynamic_bipartiteness.c3`](../../../c3/o/offline_dynamic_bipartiteness.c3) |
| C++ | [`cpp/o/offline_dynamic_bipartiteness.cpp`](../../../cpp/o/offline_dynamic_bipartiteness.cpp) |
| Elisa | [`elisa/o/offline_dynamic_bipartiteness.elisa`](../../../elisa/o/offline_dynamic_bipartiteness.elisa) |
| Mojo | [`mojo/o/offline_dynamic_bipartiteness.mojo`](../../../mojo/o/offline_dynamic_bipartiteness.mojo) |
| Nim | [`nim/o/offline_dynamic_bipartiteness.nim`](../../../nim/o/offline_dynamic_bipartiteness.nim) |
| Odin | [`odin/o/offline_dynamic_bipartiteness.odin`](../../../odin/o/offline_dynamic_bipartiteness.odin) |
| Rust | [`rust/o/offline_dynamic_bipartiteness.rs`](../../../rust/o/offline_dynamic_bipartiteness.rs) |
| V | [`v/o/offline_dynamic_bipartiteness.v`](../../../v/o/offline_dynamic_bipartiteness.v) |
| Zig | [`zig/o/offline_dynamic_bipartiteness.zig`](../../../zig/o/offline_dynamic_bipartiteness.zig) |
