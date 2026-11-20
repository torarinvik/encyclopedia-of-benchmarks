# k-Truss edge peeling decomposition

This package returns each input edge's trussness in a bounded simple
undirected graph. The edge triangle support is its number of triangles in the
current graph. The implementation initializes support, repeatedly removes a
minimum-support edge, assigns its trussness, and updates the supports of the
other two edges in each surviving incident triangle.

## Contract

- Exported symbol: `k_truss_edge_peeling_decomposition`; ABI:
  `i64_array_bytes_output`.
- Input: `[n,m,(u,v)...]`, with `1<=n<=16`, `0<=m<=120`, and exact length
  `2+2*m`. Every undirected edge is listed once with canonical endpoints
  `0<=u<v<n`. Self-loops, repeated edges, and reversed endpoint pairs are
  invalid. Input edge order is otherwise unrestricted and determines output
  order.
- Output: one little-endian signed 64-bit trussness per input edge. Every edge
  has trussness at least `2`; a triangle's edges have trussness `3`. The empty
  graph returns zero output bytes. Malformed input returns `-1`; null output or
  insufficient capacity returns `-2` without writes. Input validation takes
  precedence over output errors.
- For ties, the minimum current support is selected first, then the lowest
  input edge index. Let `level` be the largest support value peeled so far.
  Assign `max(level,support(edge))+2`. For each triangle whose other two edges
  are still alive, decrement each partner's support only when it exceeds the
  current `level`. This monotone clamp preserves the truss decomposition while
  preventing a later peel level from dropping.

The ports use a 16-by-16 adjacency table and edge-index map. Initial support
enumeration takes `O(n^3)`, minimum selection takes `O(m^2)`, and the common
neighbor scan for all peeled edges takes `O(mn)`. Workspace is `O(n^2+m)`;
the explicit arrays occupy at most 6,976 bytes in the widest list-backed port,
with a 16,384-byte package cap including bounded allocation bookkeeping and
call-local state. Output is staged before serialization and is at most 960
bytes.

## References and distinction

The [primary oracle](../../k_truss_edge_peeling_decomposition_oracle.py)
implements the same minimum-support peeling recurrence with an explicit edge
map. The independent
[threshold reference](independent_threshold_reference.py) recomputes support
and repeatedly removes all edges below each fixed `k-2` threshold; it does not
follow minimum-support peel order.

Wang and Cheng's [*Truss Decomposition in Massive Networks*](https://doi.org/10.14778/2311906.2311909)
defines a `k`-truss by its surviving edge triangle support and describes
peeling-based decomposition. The [GBBS benchmark overview](https://paralg.github.io/gbbs/docs/benchmarks/overview/)
lists k-Truss as a substructure problem; its [dedicated page](https://paralg.github.io/gbbs/docs/benchmarks/substructure/k_truss/)
currently labels the benchmark work in progress. GBBS is a title-discovery
source here, not an implementation source. This profile is distinct from
vertex k-core numbers and total triangle counting: it assigns per-edge
trussness as incident triangles disappear during peeling.

| Language | Source |
|---|---|
| C | [`c/k/k_truss_edge_peeling_decomposition.c`](../../../c/k/k_truss_edge_peeling_decomposition.c) |
| C3 | [`c3/k/k_truss_edge_peeling_decomposition.c3`](../../../c3/k/k_truss_edge_peeling_decomposition.c3) |
| C++ | [`cpp/k/k_truss_edge_peeling_decomposition.cpp`](../../../cpp/k/k_truss_edge_peeling_decomposition.cpp) |
| Elisa | [`elisa/k/k_truss_edge_peeling_decomposition.elisa`](../../../elisa/k/k_truss_edge_peeling_decomposition.elisa) |
| Mojo | [`mojo/k/k_truss_edge_peeling_decomposition.mojo`](../../../mojo/k/k_truss_edge_peeling_decomposition.mojo) |
| Nim | [`nim/k/k_truss_edge_peeling_decomposition.nim`](../../../nim/k/k_truss_edge_peeling_decomposition.nim) |
| Odin | [`odin/k/k_truss_edge_peeling_decomposition.odin`](../../../odin/k/k_truss_edge_peeling_decomposition.odin) |
| Rust | [`rust/k/k_truss_edge_peeling_decomposition.rs`](../../../rust/k/k_truss_edge_peeling_decomposition.rs) |
| V | [`v/k/k_truss_edge_peeling_decomposition.v`](../../../v/k/k_truss_edge_peeling_decomposition.v) |
| Zig | [`zig/k/k_truss_edge_peeling_decomposition.zig`](../../../zig/k/k_truss_edge_peeling_decomposition.zig) |

Fixtures are in [`workload.json`](workload.json). Rights and provenance are in
[`RIGHTS.md`](RIGHTS.md), with a static source inventory in
[`INVENTORY.md`](INVENTORY.md).
