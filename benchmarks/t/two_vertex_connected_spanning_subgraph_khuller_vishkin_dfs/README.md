# Khuller–Vishkin DFS 2-vertex-connected spanning subgraph

This package implements a bounded clean-room profile of the 2-vertex-connected
spanning-subgraph construction in Khuller and Vishkin, “Biconnectivity
Approximations and Graph Carvings,” §4.1. It is distinct from the neighboring
§3 2-edge-connected profile: this construction can discard selected DFS-tree
edges under its vertex-connectivity rule.

## Contract

- Exported symbol: `two_vertex_connected_spanning_subgraph_khuller_vishkin_dfs`.
- ABI: `i64_array_bytes_output`.
- Input: `[n,m,(u,v)*m]`, with `3<=n<=8`, `3<=m<=28`, endpoints zero based
  and normalized `u<v`. The graph must be simple and 2-vertex-connected.
  Exact valid length is `2+2*m`; 59 words are parseable so trailing data can
  be rejected. Input edge-record order determines each adjacency list's scan
  order.
- The profile roots DFS at vertex 0. It compares `low` and `low_H` by DFS
  discovery IDs and only replaces a representative on a strict improvement;
  equal candidates keep the first scan-order choice. A back edge that lowers
  `low[v]` sets `savior[v]=v`; a child that strictly lowers it transfers the
  child's `savior`.
- On finishing a non-root vertex `v`, run the paper's two checks in sequence:
  if `low_H[v]==v`, add `(savior[v],low[v])` and set `low_H[v]=low[v]`; then,
  if the updated `low_H[v]` equals the parent, add that same back edge and set
  `low_H[v]=low[v]`. In this second branch, discard the parent tree edge only
  when `savior[v]==v`. Each selected edge is retained once.
- Output is `[edge_count,(u,v)*edge_count]`, with normalized pairs sorted
  lexicographically and encoded as little-endian signed i64 values. Maximum
  output is 456 bytes. Invalid/null input returns `-1`; null or short output
  returns `-2`. Input is validated before output pointer/capacity checks, and
  errors leave output bytes untouched.

The recursive primary and explicit-stack independent reference build
input-ordered adjacency lists. The ten language ports scan the bounded edge
records in input order from each DFS frame; this preserves the prescribed
traversal while using `O(nm)` traversal work for the small profile. The paper's
construction itself is linear in `n+m`. Input validation checks the
2-vertex-connectivity precondition by deleting each vertex and testing the
remaining graph for connectivity; this bounded check costs `O(n(n+m))`. The
static inventory compares both references with each fixture and checks package
links and all ten ports.

## Source and rights

Samir Khuller and Uzi Vishkin, “Biconnectivity Approximations and Graph
Carvings,” §4.1, [author-hosted paper](https://www.cs.umd.edu/users/samir/grant/stoc92.pdf),
also published in the *Journal of the ACM*, [DOI
10.1145/174652.174654](https://doi.org/10.1145/174652.174654). The
*Encyclopedia of Algorithms* chapter is “Graph Connectivity,” [DOI
10.1007/978-1-4939-2864-4_171](https://doi.org/10.1007/978-1-4939-2864-4_171).
The sources are used for algorithm attribution only. No upstream code, prose,
figures, or test data are reproduced; see [RIGHTS.md](RIGHTS.md).

## Language ports

- [C](../../../c/t/two_vertex_connected_spanning_subgraph_khuller_vishkin_dfs.c)
- [C3](../../../c3/t/two_vertex_connected_spanning_subgraph_khuller_vishkin_dfs.c3)
- [C++](../../../cpp/t/two_vertex_connected_spanning_subgraph_khuller_vishkin_dfs.cpp)
- [Elisa](../../../elisa/t/two_vertex_connected_spanning_subgraph_khuller_vishkin_dfs.elisa)
- [Mojo](../../../mojo/t/two_vertex_connected_spanning_subgraph_khuller_vishkin_dfs.mojo)
- [Nim](../../../nim/t/two_vertex_connected_spanning_subgraph_khuller_vishkin_dfs.nim)
- [Odin](../../../odin/t/two_vertex_connected_spanning_subgraph_khuller_vishkin_dfs.odin)
- [Rust](../../../rust/t/two_vertex_connected_spanning_subgraph_khuller_vishkin_dfs.rs)
- [V](../../../v/t/two_vertex_connected_spanning_subgraph_khuller_vishkin_dfs.v)
- [Zig](../../../zig/t/two_vertex_connected_spanning_subgraph_khuller_vishkin_dfs.zig)

The bounded fixtures are in [workload.json](workload.json), with the recursive
[primary reference](primary_oracle.py) and explicit-stack
[independent reference](independent_oracle.py). The callable static inventory
is in [verify_workload.py](verify_workload.py).
