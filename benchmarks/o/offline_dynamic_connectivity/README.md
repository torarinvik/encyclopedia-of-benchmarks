# Offline dynamic connectivity

Answer connectivity queries for an undirected graph whose complete edge-add,
edge-remove, and query trace is known in advance. The algorithm assigns each
edge to its half-open active time interval, stores that interval in a segment
tree over event indices, and traverses the tree while a rollback disjoint-set
union structure maintains the active edges. The DSU uses union by size and
does not use path compression, so every successful union can be undone.

## Contract

The `i64_array_bytes_output` input is:

```text
[n, q, (op, a, b, c) repeated q times]
```

- `1 <= n <= 16`, `0 <= q <= 32`, and the input length must be exactly
  `2 + 4*q` signed 64-bit integers. Vertex IDs are zero-based.
- Add event `[0, edge_id, u, v]` inserts the undirected edge `{u,v}`. IDs are
  in `0..31`; every ID can be added only once. Distinct IDs may describe
  parallel edges, and self-edges are allowed.
- Remove event `[1, edge_id, 0, 0]` removes an active edge. An edge is active
  from its add event up to, but not including, its remove event. Any edge still
  active at the end remains active through the end of the trace.
- Query event `[2, u, v, 0]` asks whether `u` and `v` are connected after all
  earlier events. The answer is `1` or `0`. A vertex is connected to itself.
- Every reserved field must be zero. Unknown operations, duplicate edge IDs,
  invalid endpoints, and removal of inactive IDs are malformed input.
- Output contains one signed 64-bit little-endian answer per query, in event
  order. A trace with no queries returns zero bytes.
- Invalid input returns `-1`. A null output pointer or insufficient output
  capacity returns `-2`, and neither error writes output. Input validation has
  precedence over output errors.

The largest valid input has 130 integers; the parser admits one additional
integer so an overlong frame can be rejected. Output is at most 256 bytes.
Each edge interval is stored in `O(log q)` segment-tree nodes. During the
depth-first traversal, rollback DSU finds and unions take `O(log n)` worst-case
time. This implementation scans later events to find each removed edge's end,
then traverses the time tree, for `O(q + a*q + a log(q+1) log(n+1))` work for
`a` additions. The current fixed-size bucket tables reserve `O(q^2 + n)`
storage at these bounds.

## Workload and oracle

[`workload.json`](workload.json) covers additions, removals, parallel edges,
self-connectivity, queries on both sides of updates, edges active through the
end, an empty-query trace, malformed event records, and output errors. The
independent [`offline_dynamic_connectivity_oracle.py`](../../offline_dynamic_connectivity_oracle.py)
rebuilds the active adjacency list and runs a fresh BFS for every query; it
does not use a segment tree or rollback DSU.

## Source and implementation

The [OI Wiki article](https://oi-wiki.org/topic/segment-tree-offline/) supplies
the offline interval-over-time and rollback technique. The edge-ID event
encoding, the `n <= 16` and `q <= 32` bounds, error sentinels, and byte-output
contract above are this repository's bounded benchmark profile; they are not
claimed as the article's task specification. The implementations are
clean-room ports of the method, not copied code.

| Language | Port |
|---|---|
| C | [`c/o/offline_dynamic_connectivity.c`](../../../c/o/offline_dynamic_connectivity.c) |
| C3 | [`c3/o/offline_dynamic_connectivity.c3`](../../../c3/o/offline_dynamic_connectivity.c3) |
| C++ | [`cpp/o/offline_dynamic_connectivity.cpp`](../../../cpp/o/offline_dynamic_connectivity.cpp) |
| Elisa | [`elisa/o/offline_dynamic_connectivity.elisa`](../../../elisa/o/offline_dynamic_connectivity.elisa) |
| Mojo | [`mojo/o/offline_dynamic_connectivity.mojo`](../../../mojo/o/offline_dynamic_connectivity.mojo) |
| Nim | [`nim/o/offline_dynamic_connectivity.nim`](../../../nim/o/offline_dynamic_connectivity.nim) |
| Odin | [`odin/o/offline_dynamic_connectivity.odin`](../../../odin/o/offline_dynamic_connectivity.odin) |
| Rust | [`rust/o/offline_dynamic_connectivity.rs`](../../../rust/o/offline_dynamic_connectivity.rs) |
| V | [`v/o/offline_dynamic_connectivity.v`](../../../v/o/offline_dynamic_connectivity.v) |
| Zig | [`zig/o/offline_dynamic_connectivity.zig`](../../../zig/o/offline_dynamic_connectivity.zig) |
