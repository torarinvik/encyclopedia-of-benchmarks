# Dynamic graph vertex-add component sum

Maintain an undirected graph under edge insertions and deletions, add values to
vertices, and report the current sum of the queried vertex's connected
component. This package is distinct from
[`offline_dynamic_connectivity`](../../o/offline_dynamic_connectivity/README.md):
it must roll back vertex-weight deltas and component aggregates in addition to
edge unions.

## Contract

The `i64_array_bytes_output` input is
`[n, q, initial_value_0..initial_value_(n-1), (op, a, b) * q]`.

- `1 <= n <= 16`; `0 <= q <= 32`; input length is exactly `2+n+3q`.
- Initial values and vertex-add deltas are in `0..=100`. Their component sums
  are at most `16*100 + 32*100 = 4,800`, since the 32-event limit is shared
  by edge and value operations.
- Vertices are zero-based. Edges are simple and undirected; self-loops and
  duplicate active edges are invalid. Adding an edge requires it to be absent;
  removing one requires it to be present. Endpoints may be supplied in either
  order.
- Events are fixed triples: `[0,u,v]` adds edge `{u,v}`; `[1,u,v]` removes it;
  `[2,v,x]` adds `x` to vertex `v`; `[3,v,0]` queries the component sum at `v`.
  The third query field must be zero. Each query observes all earlier updates.
- Output is one signed 64-bit little-endian sum per query, in event order. A
  trace with no queries returns zero bytes.
- Malformed input returns `-1`. Null output and insufficient capacity return
  `-2`; input validation takes precedence. No output is written on either
  error.

The maximum valid input has 114 words; one extra word is parseable so an
overlong frame is rejected explicitly. Output is bounded at 256 bytes, with a
fixed 262,144-byte internal workspace allowance for interval buckets, rollback
state, and staged answers.

## Algorithm

The ports convert each edge's active lifetime to a half-open interval over
event indices. Initial vertex values and each later value delta are also
represented as time intervals over which the contribution is active. These
intervals are placed in a segment tree over time. A depth-first traversal
applies the node's edge unions and vertex deltas to a rollback DSU, answers
component-sum queries at leaves, and restores the DSU state on return. The DSU
uses union by size without path compression; its history stores parent/size,
component-sum, and vertex-delta changes.

This is an offline bounded profile of the official operation stream. It does
not implement the official large-input online data structure. A direct graph
simulation with a fresh traversal at each query is used as the primary oracle;
the independent verifier rebuilds a DSU from active edges at every query.

## Source and rights

The operation contract follows Library Checker’s
[`dynamic_graph_vertex_add_component_sum/task.md`](https://github.com/yosupo06/library-checker-problems/blob/master/graph/dynamic_graph_vertex_add_component_sum/task.md)
and bounds in its
[`info.toml`](https://github.com/yosupo06/library-checker-problems/blob/master/graph/dynamic_graph_vertex_add_component_sum/info.toml).
The task repository is distributed under Apache-2.0. The ports and oracles are
clean-room implementations; no upstream solution code is copied or translated.
See [`RIGHTS.md`](RIGHTS.md) for attribution and license details.

## Workload and implementations

[`workload.json`](workload.json) includes edge lifetime changes, vertex-value
updates, component queries before and after splits, maximum-size framing,
invalid traces, null output, and capacity errors.

| Language | Port |
|---|---|
| C | [`c/d/dynamic_graph_vertex_add_component_sum.c`](../../../c/d/dynamic_graph_vertex_add_component_sum.c) |
| C3 | [`c3/d/dynamic_graph_vertex_add_component_sum.c3`](../../../c3/d/dynamic_graph_vertex_add_component_sum.c3) |
| C++ | [`cpp/d/dynamic_graph_vertex_add_component_sum.cpp`](../../../cpp/d/dynamic_graph_vertex_add_component_sum.cpp) |
| Elisa | [`elisa/d/dynamic_graph_vertex_add_component_sum.elisa`](../../../elisa/d/dynamic_graph_vertex_add_component_sum.elisa) |
| Mojo | [`mojo/d/dynamic_graph_vertex_add_component_sum.mojo`](../../../mojo/d/dynamic_graph_vertex_add_component_sum.mojo) |
| Nim | [`nim/d/dynamic_graph_vertex_add_component_sum.nim`](../../../nim/d/dynamic_graph_vertex_add_component_sum.nim) |
| Odin | [`odin/d/dynamic_graph_vertex_add_component_sum.odin`](../../../odin/d/dynamic_graph_vertex_add_component_sum.odin) |
| Rust | [`rust/d/dynamic_graph_vertex_add_component_sum.rs`](../../../rust/d/dynamic_graph_vertex_add_component_sum.rs) |
| V | [`v/d/dynamic_graph_vertex_add_component_sum.v`](../../../v/d/dynamic_graph_vertex_add_component_sum.v) |
| Zig | [`zig/d/dynamic_graph_vertex_add_component_sum.zig`](../../../zig/d/dynamic_graph_vertex_add_component_sum.zig) |

Primary oracle: [`dynamic_graph_vertex_add_component_sum_oracle.py`](../../dynamic_graph_vertex_add_component_sum_oracle.py).
Independent verifier oracle: [`dynamic_graph_vertex_add_component_sum_verifier_oracle.py`](../../dynamic_graph_vertex_add_component_sum_verifier_oracle.py).
