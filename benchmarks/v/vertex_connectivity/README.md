# Global vertex connectivity

This benchmark computes the vertex connectivity of a bounded undirected graph.
It follows the vertex-splitting reduction described in the CP-Algorithms
[edge and vertex connectivity article](https://cp-algorithms.com/graph/edge_vertex_connectivity.html): for each nonadjacent terminal pair, split every vertex into an in/out pair, assign unit capacity to internal vertex arcs and graph arcs, then compute a maximum flow. The least such flow is the minimum vertex separator. A complete graph on `n>=2` vertices has value `n-1`.

## Contract

- Input is `[vertex_count, edge_count, (left,right)*edge_count]` with zero-based vertices, `0<=vertex_count<=10`, and `0<=edge_count<=45`.
- The input length must be exactly `2+2*edge_count`. Invalid framing or endpoints return `-1`.
- The graph is undirected and simple. Repeated edges are coalesced; self-loops are ignored.
- Disconnected graphs and graphs with at most one vertex return `0`. Complete graphs return `n-1`; other connected graphs return the minimum number of removed vertices that disconnects the graph.
- The result is one signed 64-bit scalar. The bounded ports use at most 470 workspace elements, including the fixed-array helper copy in Zig.

The primary oracle uses the same vertex-splitting reduction with Edmonds–Karp. The independent oracle enumerates vertex-deletion subsets and counts connected components directly. This computes arbitrary vertex-separator cardinality, while [`articulation_points`](../../a/articulation_points/README.md) detects only size-one cuts. It is also distinct from bridge finding and global edge minimum cut.

## Source and rights

CP-Algorithms attributes the article to its contributors and licenses its text
under CC BY-SA 4.0. This package uses only the high-level algorithm description
for attribution and writes the implementations, oracles, input contract, and
fixtures independently. No article prose, code, or test data is reproduced.

## Language ports

- [`c/v/vertex_connectivity.c`](../../../c/v/vertex_connectivity.c)
- [`c3/v/vertex_connectivity.c3`](../../../c3/v/vertex_connectivity.c3)
- [`cpp/v/vertex_connectivity.cpp`](../../../cpp/v/vertex_connectivity.cpp)
- [`elisa/v/vertex_connectivity.elisa`](../../../elisa/v/vertex_connectivity.elisa)
- [`mojo/v/vertex_connectivity.mojo`](../../../mojo/v/vertex_connectivity.mojo)
- [`nim/v/vertex_connectivity.nim`](../../../nim/v/vertex_connectivity.nim)
- [`odin/v/vertex_connectivity.odin`](../../../odin/v/vertex_connectivity.odin)
- [`rust/v/vertex_connectivity.rs`](../../../rust/v/vertex_connectivity.rs)
- [`v/v/vertex_connectivity.v`](../../../v/v/vertex_connectivity.v)
- [`zig/v/vertex_connectivity.zig`](../../../zig/v/vertex_connectivity.zig)

The bounded fixtures and metadata are in [`workload.json`](workload.json); the
package-local static inventory checker is
[`verify_vertex_connectivity_package.py`](verify_vertex_connectivity_package.py).
