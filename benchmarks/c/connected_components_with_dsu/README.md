# Connected components with disjoint-set union

This benchmark counts the connected components of an undirected graph using a disjoint-set union (DSU). It processes every edge once, joins roots by set size, and uses path halving when finding a root.

## Contract

- Input is `[node_count, edge_count, (left, right) * edge_count]`.
- Vertices use the source's one-based IDs. `node_count` is 0–256 and `edge_count` is 0–2,047. Each endpoint must be in `[1, node_count]`; self-edges and repeated edges are allowed.
- The input must have exactly `2 + 2 * edge_count` values. Invalid counts, endpoints, or lengths return `-1`.
- The scalar result is the number of connected components. An empty graph returns 0; an edgeless graph with `n` vertices returns `n`.

The pinned C++ DSU source initializes vertices 1 through `n`, merges roots by component size, uses path halving, then counts distinct roots. This is a separate algorithm from the DFS connected-components candidates, which traverse components and may return component groups or representatives. It is also separate from the general [`union_find`](../../u/union_find/README.md) operation-trace benchmark.

## Workload

[`workload.json`](workload.json) covers empty and edgeless graphs, disconnected subgraphs, duplicate and self-edges, the maximum edge count, and malformed input. Runtime verification is pending.

Build and record with the `i64_array_scalar` ABI family.

## Upstream sources

- [TheAlgorithms/C-Plus-Plus DSU connected-components source at the pinned revision](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/graph/connected_components_with_dsu.cpp)
- [The additional C++ source copy](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/graph/connected_components_with_dsu.cpp)
- [DFS connected-components source in C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/graph/connected_components.cpp), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/connected_components.py), and [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Graphs/ConnectedComponents.js)
