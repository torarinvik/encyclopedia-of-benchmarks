# Tree height

Compute the height of a rooted, undirected tree with root node `1`. The benchmark ports the bottom-up depth-first dynamic programming routine from [TheAlgorithms C++ `tree_height.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/dynamic_programming/tree_height.cpp); the pinned C++-1 copy has the same source. The DFS stores each node's height after visiting its children. A leaf has height one, so the result counts nodes on the longest root-to-leaf path.

This is a general rooted tree: any node may have more than two children. That makes it a distinct contract from [`max_depth`](../../m/max_depth/README.md), which accepts a binary tree. The shared array-scalar ABI packs the input as `[node_count, edge_u0, edge_v0, ...]`; each edge is undirected and node labels are `1..node_count`. The root is fixed at node `1`.

## Bounds and invalid inputs

- `1 <= node_count <= 1,023`, with exactly `node_count - 1` edges.
- Every edge endpoint must be in `1..node_count`. The edges must form one connected tree; invalid packed inputs return `-1`.
- The node bound keeps the recursive DFS depth bounded and also stays within the source's one-based adjacency-array index range.

The workload uses the `i64_array_scalar` ABI and `i64_array_scalar_call` comparison model.
