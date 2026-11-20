# Weighted two-vertex cuts by bounded SPQR decomposition

This benchmark builds a split-component decomposition of a small biconnected
simple graph, reduces adjacent series and parallel skeletons, enumerates its
2-cut pairs, and aggregates the number of components left after deleting each
pair. It benchmarks the SPQR/triconnected-decomposition algorithm family. It
does not benchmark vertex connectivity: [`vertex_connectivity`](../../v/vertex_connectivity/README.md)
returns only the minimum separator cardinality using vertex-split max flow.

## Contract

- ABI: `i64_array_scalar`; exported symbol: `two_vertex_cuts_spqr`.
- Input is `[N, M, weights[N], (u, v)*M]`, with zero-based vertex IDs and
  undirected edges.
- `3 <= N <= 8`, `3 <= M <= 28`, every weight is in `0..1,000,000`, and the
  exact input length is `2 + N + 2*M`. The maximum valid length is 66 i64
  values; the maximum parseable length is 67.
- The graph must be simple and biconnected. Loops, duplicate edges, invalid
  endpoints, disconnected graphs, and graphs with an articulation vertex
  return `-1`, as do invalid lengths, headers, or weights.
- The result is
  `sum_{u<v} weights[u]*weights[v]*(cc(G - {u,v}) - 1) mod 998244353`,
  returned as one signed 64-bit scalar.

## Algorithm profile

Each current split piece is scanned in lexicographic pole order. Its separation
classes are the edge sets of the components after removing the two poles,
plus one singleton class for each direct pole edge. A deterministic proper
split partitions these classes into two sides with at least two edge
occurrences each, then adds a paired virtual edge to both children. The first
class with size from two through `E-2` is isolated when available; otherwise,
if all classes are singleton and there are at least four, the first two are
grouped against the rest. The recursion stops when no proper split remains.

Terminal pieces are triangles (S), triple bonds (P), or rigid triconnected
pieces (R). The implementation keeps original edges as real skeleton edges and
virtual edges as paired split links; it does not create Q leaves. Adjacent S
pieces and adjacent P pieces are merged through their shared virtual edge. Cut
candidates are the split-pair poles, the poles of P skeletons, and
nonconsecutive vertex pairs on S cycles. A small BFS on the original graph
counts components for each candidate. This bounded exhaustive split discovery
is intentionally not a linear-time implementation; its conservative bound is
`O(M*N^2*(N+M))` time and `O(M^2)` storage.

The primary reference constructs this split decomposition. The independent
reference ignores the decomposition and scans every vertex pair, deleting the
pair and counting components directly. Both are bounded to eight vertices.
They are provided as [`two_vertex_cuts_spqr_oracle.py`](two_vertex_cuts_spqr_oracle.py)
and [`two_vertex_cuts_spqr_independent_oracle.py`](two_vertex_cuts_spqr_independent_oracle.py).
The workload includes S, P, and R structures, mixed skeletons, real pole
edges, manually derived nonzero outputs, zero-weight rich structures, and
invalid frames. No reference implementation or benchmark was executed while
preparing this package.

## Sources

- [Library Checker Two-Vertex Cuts proposal #1427](https://github.com/yosupo06/library-checker-problems/issues/1427) supplies the weighted aggregate objective and identifies SPQR trees.
- Gutwenger and Mutzel, [“A Linear Time Implementation of SPQR-Trees”](https://doi.org/10.1007/3-540-44541-2_8), supplies the split-component and reduced-skeleton definitions. The benchmark uses a bounded exhaustive split-pair search rather than their linear-time lowpoint procedure.
- Hopcroft and Tarjan, [“Dividing a Graph into Triconnected Components”](https://doi.org/10.1137/0202012), is the classical triconnected-decomposition reference. The Gutwenger–Mutzel corrections are followed at the level of split/merge definitions; the old lowpoint pseudocode is not copied.

## Language ports

- [`c/t/two_vertex_cuts_spqr.c`](../../../c/t/two_vertex_cuts_spqr.c)
- [`c3/t/two_vertex_cuts_spqr.c3`](../../../c3/t/two_vertex_cuts_spqr.c3)
- [`cpp/t/two_vertex_cuts_spqr.cpp`](../../../cpp/t/two_vertex_cuts_spqr.cpp)
- [`elisa/t/two_vertex_cuts_spqr.elisa`](../../../elisa/t/two_vertex_cuts_spqr.elisa)
- [`mojo/t/two_vertex_cuts_spqr.mojo`](../../../mojo/t/two_vertex_cuts_spqr.mojo)
- [`nim/t/two_vertex_cuts_spqr.nim`](../../../nim/t/two_vertex_cuts_spqr.nim)
- [`odin/t/two_vertex_cuts_spqr.odin`](../../../odin/t/two_vertex_cuts_spqr.odin)
- [`rust/t/two_vertex_cuts_spqr.rs`](../../../rust/t/two_vertex_cuts_spqr.rs)
- [`v/t/two_vertex_cuts_spqr.v`](../../../v/t/two_vertex_cuts_spqr.v)
- [`zig/t/two_vertex_cuts_spqr.zig`](../../../zig/t/two_vertex_cuts_spqr.zig)

Fixtures and metadata are in [`workload.json`](workload.json). The package-local
static inventory verifier is [`verify_two_vertex_cuts_spqr_package.py`](verify_two_vertex_cuts_spqr_package.py).
