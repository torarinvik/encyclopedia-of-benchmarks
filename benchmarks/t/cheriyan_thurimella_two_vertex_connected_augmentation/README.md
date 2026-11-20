# Cheriyan–Thurimella matching-based 2-vertex-connected augmentation

This bounded profile implements the two-step heuristic of Cheriyan and
Thurimella for a minimum-size 2-vertex-connected spanning subgraph. First it
constructs a minimum edge cover from a maximum matching; then it scans the
remaining input edges and removes an edge whenever the current graph remains
2-vertex-connected.

## Contract

- ABI: `i64_array_bytes_output`; exported symbol:
  `cheriyan_thurimella_two_vertex_connected_augmentation`.
- Input is `[n,m,(u,v)*m]`, with `3<=n<=8`, `3<=m<=28`, a simple undirected
  graph, and each edge normalized as `u<v`. The graph must be
  2-vertex-connected. Input edge order determines adjacency order, matching
  tie resolution, and the greedy deletion scan.
- The first step uses a subset DP for a maximum-cardinality matching. For the
  lowest remaining vertex, it considers incident edges in input-record order,
  retaining the first maximum-cardinality choice; leaving the vertex
  unmatched is considered after those edge choices. Each unmatched vertex is
  covered by its earliest incident input edge. This is a minimum edge cover
  because a maximum matching leaves no adjacent pair of uncovered vertices.
- The second step begins with all input edges present. In input-record order,
  each edge outside the fixed edge cover is temporarily removed. It stays
  removed exactly when every single-vertex deletion leaves a connected graph.
  The scan is sequential; later deletions do not revisit earlier decisions.
- Output is `[edge_count,(u,v)*edge_count]`, with selected pairs in original
  input-record order and little-endian signed i64 encoding. Invalid input,
  including a graph that fails the 2-connectivity precondition, returns `-1`.
  Null or undersized output returns `-2`; errors leave output untouched.
- The bounded matching DP costs `O(2^n m)`. Each biconnectivity check scans
  all `m` records from each BFS vertex for each of the `n` deleted vertices;
  validation plus the sequential edge scan therefore costs
  `O(n^2 m^2)`. Total time is `O(2^n m+n^2 m^2)` and auxiliary storage is
  `O(2^n+n+m)`.

The primary reference uses bottom-up subset DP and breadth-first deletion
checks. The independent reference enumerates matching branches and uses an
articulation-point search. The fixtures include a triangle with an unmatched
vertex, a permuted 4-cycle, a dense graph with greedy edge removal, invalid
preconditions, and output-capacity errors.

## Source and rights

Joseph Cheriyan and Ramakrishna Thurimella, “Approximating Minimum-Size
k-Connected Spanning Subgraphs via Matching,” *SIAM Journal on Computing*
30(2), 528–560 (2000), [author-hosted paper, §3.1](https://www.cs.du.edu/~ramki/papers/spanSubgraphs.pdf).
The profile fixes `k=2` for vertex connectivity. The paper describes the
minimum-degree edge set followed by sequential critical-edge testing; the
bounded tie rules are specified here. Only algorithm ideas and attribution
are used; no source code, prose, examples, or test data are copied. See
[RIGHTS.md](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [`c/t/cheriyan_thurimella_two_vertex_connected_augmentation.c`](../../../c/t/cheriyan_thurimella_two_vertex_connected_augmentation.c) |
| C3 | [`c3/t/cheriyan_thurimella_two_vertex_connected_augmentation.c3`](../../../c3/t/cheriyan_thurimella_two_vertex_connected_augmentation.c3) |
| C++ | [`cpp/t/cheriyan_thurimella_two_vertex_connected_augmentation.cpp`](../../../cpp/t/cheriyan_thurimella_two_vertex_connected_augmentation.cpp) |
| Elisa | [`elisa/t/cheriyan_thurimella_two_vertex_connected_augmentation.elisa`](../../../elisa/t/cheriyan_thurimella_two_vertex_connected_augmentation.elisa) |
| Mojo | [`mojo/t/cheriyan_thurimella_two_vertex_connected_augmentation.mojo`](../../../mojo/t/cheriyan_thurimella_two_vertex_connected_augmentation.mojo) |
| Nim | [`nim/t/cheriyan_thurimella_two_vertex_connected_augmentation.nim`](../../../nim/t/cheriyan_thurimella_two_vertex_connected_augmentation.nim) |
| Odin | [`odin/t/cheriyan_thurimella_two_vertex_connected_augmentation.odin`](../../../odin/t/cheriyan_thurimella_two_vertex_connected_augmentation.odin) |
| Rust | [`rust/t/cheriyan_thurimella_two_vertex_connected_augmentation.rs`](../../../rust/t/cheriyan_thurimella_two_vertex_connected_augmentation.rs) |
| V | [`v/t/cheriyan_thurimella_two_vertex_connected_augmentation.v`](../../../v/t/cheriyan_thurimella_two_vertex_connected_augmentation.v) |
| Zig | [`zig/t/cheriyan_thurimella_two_vertex_connected_augmentation.zig`](../../../zig/t/cheriyan_thurimella_two_vertex_connected_augmentation.zig) |

See [workload.json](workload.json), the [primary reference](primary_oracle.py),
the [independent reference](independent_oracle.py), and the callable package
review [verify_workload.py](verify_workload.py).
