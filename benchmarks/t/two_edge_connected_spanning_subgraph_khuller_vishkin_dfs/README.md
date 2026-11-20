# Khuller–Vishkin DFS 2-edge-connected spanning subgraph

This benchmark profiles the linear-time DFS construction from Khuller and
Vishkin's 3/2-approximation for an unweighted minimum 2-edge-connected
spanning subgraph. It is distinct from
[`two_edge_connected_spanning_subgraph_greedy`](../two_edge_connected_spanning_subgraph_greedy/README.md),
which starts with all input edges and greedily deletes edges in a chosen order.
This profile keeps the DFS tree and adds a selected set of back edges.

## Contract

- ABI: `i64_array_bytes_output`; symbol:
  `two_edge_connected_spanning_subgraph_khuller_vishkin_dfs`.
- Input is `[n,m,(u,v)*m]`, with zero-based vertices and normalized endpoints
  `u<v`. The graph is simple, undirected, and initially 2-edge-connected.
- Bounds are `3<=n<=8`, `3<=m<=28`, and exact length `2+2*m`. Maximum valid
  and parseable lengths are 58 and 59 signed 64-bit words.
- The profile roots DFS at vertex 0. Each vertex scans incident edges in input
  record order. Discovery numbers break all `low`/`low_H` comparisons; equal
  values keep the first choice encountered. This pins the source pseudocode's
  otherwise arbitrary root and adjacency iteration order.
- The construction maintains `low[v]`, `low_H[v]`, and `savior[v]` as in the
  paper's recursive procedure. The ports simulate its recursion with a fixed
  explicit DFS event stack. It keeps every DFS tree edge. When a non-root vertex finishes with
  `low_H[v]==v`, it also keeps the back edge `(savior[v],low[v])` and sets
  `low_H[v]=low[v]`. Duplicate edge selections are represented once.
- Output is `[edge_count,(u,v)*edge_count]`, with pairs sorted
  lexicographically and encoded as little-endian signed i64. The maximum output
  is 456 bytes. Invalid input returns `-1`; null or insufficient output returns
  `-2` without writing.

With adjacency lists, the paper's DFS construction is `O(n+m)` time and space.
These bounded ports scan the ordered edge records to enumerate each vertex's
neighbors, so their DFS traversal takes `O(nm)` time and `O(n+m)` space. The
profile also validates the 2-edge-connectivity precondition by reachability
after each single-edge deletion, using `O(m(n+m))` time; this check is only for
input validation.

The primary oracle follows the recursive paper procedure. The independent
reference uses an explicit DFS event stack and a separate bridge test. The
workload includes cycle, dense, multi-back-edge, maximum-frame, malformed,
and output-ABI cases. No implementation or oracle was run while preparing the
fixtures.

## Source and rights

Samir Khuller and Uzi Vishkin, “Biconnectivity Approximations and Graph
Carvings,” §3.1, [primary paper](https://www.cs.umd.edu/users/samir/grant/stoc92.pdf),
also published in the *Journal of the ACM*,
[DOI 10.1145/174652.174654](https://doi.org/10.1145/174652.174654). The
chapter's summary is “Graph Connectivity,” DOI
[10.1007/978-1-4939-2864-4_171](https://doi.org/10.1007/978-1-4939-2864-4_171).
The mathematical procedure is used as an idea reference; no source code, prose,
figures, or test data is copied. See [RIGHTS.md](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [`c/t/two_edge_connected_spanning_subgraph_khuller_vishkin_dfs.c`](../../../c/t/two_edge_connected_spanning_subgraph_khuller_vishkin_dfs.c) |
| C3 | [`c3/t/two_edge_connected_spanning_subgraph_khuller_vishkin_dfs.c3`](../../../c3/t/two_edge_connected_spanning_subgraph_khuller_vishkin_dfs.c3) |
| C++ | [`cpp/t/two_edge_connected_spanning_subgraph_khuller_vishkin_dfs.cpp`](../../../cpp/t/two_edge_connected_spanning_subgraph_khuller_vishkin_dfs.cpp) |
| Elisa | [`elisa/t/two_edge_connected_spanning_subgraph_khuller_vishkin_dfs.elisa`](../../../elisa/t/two_edge_connected_spanning_subgraph_khuller_vishkin_dfs.elisa) |
| Mojo | [`mojo/t/two_edge_connected_spanning_subgraph_khuller_vishkin_dfs.mojo`](../../../mojo/t/two_edge_connected_spanning_subgraph_khuller_vishkin_dfs.mojo) |
| Nim | [`nim/t/two_edge_connected_spanning_subgraph_khuller_vishkin_dfs.nim`](../../../nim/t/two_edge_connected_spanning_subgraph_khuller_vishkin_dfs.nim) |
| Odin | [`odin/t/two_edge_connected_spanning_subgraph_khuller_vishkin_dfs.odin`](../../../odin/t/two_edge_connected_spanning_subgraph_khuller_vishkin_dfs.odin) |
| Rust | [`rust/t/two_edge_connected_spanning_subgraph_khuller_vishkin_dfs.rs`](../../../rust/t/two_edge_connected_spanning_subgraph_khuller_vishkin_dfs.rs) |
| V | [`v/t/two_edge_connected_spanning_subgraph_khuller_vishkin_dfs.v`](../../../v/t/two_edge_connected_spanning_subgraph_khuller_vishkin_dfs.v) |
| Zig | [`zig/t/two_edge_connected_spanning_subgraph_khuller_vishkin_dfs.zig`](../../../zig/t/two_edge_connected_spanning_subgraph_khuller_vishkin_dfs.zig) |

See [workload.json](workload.json), the [primary oracle](primary_oracle.py),
the [independent oracle](independent_oracle.py), the callable package review
[`verify_workload.py`](verify_workload.py), and the static inventory checker
[check_inventory.py](check_inventory.py).
