# Khuller–Raghavachari 3-edge-connected spanning subgraph

This bounded profile implements the unweighted phased DFS construction from
Khuller and Raghavachari, specialized to `k=3`. It first uses one even
connectivity phase to make the solution 2-edge-connected, then adds a maximal
spanning forest of the remaining input graph to raise connectivity to three.

## Contract

- ABI: `i64_array_bytes_output`; exported symbol:
  `khuller_raghavachari_three_edge_connected_spanning_subgraph`.
- Input is `[n,m,(u,v)*m]`, with `4<=n<=8`, `6<=m<=28`, a simple undirected
  graph, normalized endpoints `u<v`, and 3-edge-connected input. Input record
  order determines DFS adjacency order, highest-going tie resolution, and the
  final residual-forest scan.
- The first phase roots DFS at vertex 0 and takes its spanning tree. Tree edges
  are processed in DFS postorder. If the parent and child are still separated
  by a one-edge cut in the current solution, add an unused edge crossing the
  child's DFS subtree whose outside endpoint has the smallest discovery ID;
  input record order breaks remaining ties. This is the phase's
  highest-going back edge.
- The odd-`k` final step scans unused input edges in record order and adds each
  edge that joins two components of the unused-edge graph's growing forest.
  Output records are selected input edges in original input order.
- Invalid input or a graph that fails the 3-edge-connectivity precondition
  returns `-1`. Null or short output returns `-2`; errors leave output
  untouched. Maximum input and parseable lengths are 58 and 59 words;
  maximum output is 456 bytes.
- The bounded cut precheck costs `O(2^n m)`. A tree-edge check tries each
  selected edge and runs an edge-record-scan BFS, giving total time
  `O(2^n m+n^2 m^2)` for the phase and final forest. Auxiliary storage is
  `O(n+m)`.

The primary reference uses recursive DFS and edge-deletion BFS tests. The
independent reference uses an explicit DFS stack and enumerates separating
cuts for each tree-edge endpoint pair. The workload includes K4, K5, invalid
connectivity, framing, null-buffer, and short-buffer cases.

## Source and rights

Samir Khuller and B. Raghavachari, “Improved Approximation Algorithms for
Uniform Connectivity Problems,” §3.1, [primary paper](https://www.cs.du.edu/~snarayan/sada/research/docs/p1-khuller.pdf).
The source describes the depth-first maximal forest, postorder connectivity
checks, highest-going back-edge choice, and odd-`k` residual forest. This
package uses algorithm ideas only; no source code, prose, examples, or test
data are copied. See [RIGHTS.md](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [`c/t/khuller_raghavachari_three_edge_connected_spanning_subgraph.c`](../../../c/t/khuller_raghavachari_three_edge_connected_spanning_subgraph.c) |
| C3 | [`c3/t/khuller_raghavachari_three_edge_connected_spanning_subgraph.c3`](../../../c3/t/khuller_raghavachari_three_edge_connected_spanning_subgraph.c3) |
| C++ | [`cpp/t/khuller_raghavachari_three_edge_connected_spanning_subgraph.cpp`](../../../cpp/t/khuller_raghavachari_three_edge_connected_spanning_subgraph.cpp) |
| Elisa | [`elisa/t/khuller_raghavachari_three_edge_connected_spanning_subgraph.elisa`](../../../elisa/t/khuller_raghavachari_three_edge_connected_spanning_subgraph.elisa) |
| Mojo | [`mojo/t/khuller_raghavachari_three_edge_connected_spanning_subgraph.mojo`](../../../mojo/t/khuller_raghavachari_three_edge_connected_spanning_subgraph.mojo) |
| Nim | [`nim/t/khuller_raghavachari_three_edge_connected_spanning_subgraph.nim`](../../../nim/t/khuller_raghavachari_three_edge_connected_spanning_subgraph.nim) |
| Odin | [`odin/t/khuller_raghavachari_three_edge_connected_spanning_subgraph.odin`](../../../odin/t/khuller_raghavachari_three_edge_connected_spanning_subgraph.odin) |
| Rust | [`rust/t/khuller_raghavachari_three_edge_connected_spanning_subgraph.rs`](../../../rust/t/khuller_raghavachari_three_edge_connected_spanning_subgraph.rs) |
| V | [`v/t/khuller_raghavachari_three_edge_connected_spanning_subgraph.v`](../../../v/t/khuller_raghavachari_three_edge_connected_spanning_subgraph.v) |
| Zig | [`zig/t/khuller_raghavachari_three_edge_connected_spanning_subgraph.zig`](../../../zig/t/khuller_raghavachari_three_edge_connected_spanning_subgraph.zig) |

See [workload.json](workload.json), both references, and callable package
review [verify_workload.py](verify_workload.py).
