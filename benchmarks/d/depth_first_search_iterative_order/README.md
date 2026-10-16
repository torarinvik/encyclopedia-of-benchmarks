# Iterative Depth-First Search Order

This benchmark returns the visit order produced by the iterative `DFSIterative` method in the pinned JavaScript `Graph3` class. It keeps the source's explicit stack, adjacency insertion order, and visited-at-push behavior.

## Contract

- Input is `[node_count, edge_count, (left, right)..., start]` as signed 64-bit integers. Nodes are the integers `1` through `node_count`; `node_count` is 1–10 and `edge_count` is 0–64.
- Edges are undirected. Repeated edges and self-loops are accepted and appended to both endpoint rows, matching `addEdge`. The start and every edge endpoint must name a declared node. Node zero is excluded because the source returns `null` for a falsy start.
- The traversal marks each node visited when it is pushed. It scans each adjacency row in insertion order and pops from the end of the stack; this means siblings are visited in reverse push order, while a node already pending from another branch is not pushed again.
- Output is a little-endian signed 64-bit vector `[visit_count, visited_node...]`. The function returns the number of output bytes, `-1` for malformed input, and `-2` when output storage is missing or too small.

The same `Graph3.js` file also implements recursive DFS and BFS; those traversal contracts are represented by [`graph_js_undirected_unweighted`](../../g/graph_js_undirected_unweighted/README.md). This package captures its distinct iterative traversal order.

[`workload.json`](workload.json) covers chains, branching, cross edges, duplicate edges, self-loops, disconnected nodes, and invalid input. Record measurements with [`benchmarks/run_i64_array_bytes_output.py`](../../run_i64_array_bytes_output.py).

## Pinned source

- [TheAlgorithms/JavaScript `Graph3.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Graph/Graph3.js)
