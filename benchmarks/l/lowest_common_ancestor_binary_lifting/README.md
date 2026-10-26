# Lowest Common Ancestor by Binary Lifting

Build a rooted view of an undirected tree, then answer a batch of lowest-common-ancestor queries with a sparse ancestor table. The stable vertex IDs make the result unambiguous and let all ports share one contract.

## Contract

- Input is `[node_count, root_id, edge_count, query_count, (edge_u, edge_v) * edge_count, (query_u, query_v) * query_count]`.
- Vertex IDs are zero-based. `1 <= node_count <= 256`; the input must contain exactly `node_count - 1` valid, non-self edges and describe one connected acyclic tree. The root and every query endpoint must be valid IDs. `0 <= query_count <= 1024`.
- Return one unsigned byte per query, in input order. Each byte is the vertex ID of the lowest common ancestor. A query `(v, v)` returns `v`; a zero-query batch returns zero bytes.
- Invalid input or a graph that is not a tree returns `-1`. Insufficient output capacity returns `-2`. The input is read only.
- Implementations root the tree, fill binary ancestors, and answer each query in `O(log n)` after `O(n log n)` preprocessing. Auxiliary space is `O(n log n)`.

The batched edge-list contract is shared with [`lowest_common_ancestor_tarjan`](../lowest_common_ancestor_tarjan/README.md), which answers the same queries with Tarjan's offline DSU algorithm. The existing [`lowest_common_ancestor`](../lowest_common_ancestor/README.md) benchmark instead compares root-to-target paths in an indexed binary tree.
The JavaScript `LCABinaryLifting` source uses the same binary-lifting query algorithm; its weighted checksum is a projection of the answer sequence and is tracked as an alias.

## Workload

[`workload.json`](workload.json) covers same-vertex, balanced-tree, arbitrary-root, star, zero-query, maximum-size chain, maximum-query, maximum tree and query counts together, malformed-edge, disconnected-cycle, and invalid-query cases. The shared byte-output recorder checks the exact LCA byte sequence.

## Upstream sources

- [TheAlgorithms/C++ lowest common ancestor](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/graph/lowest_common_ancestor.cpp)
- [TheAlgorithms/C-Plus-Plus-1 lowest common ancestor](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/graph/lowest_common_ancestor.cpp)
- [TheAlgorithms/Python lowest common ancestor](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/binary_tree/lowest_common_ancestor.py)
- [TheAlgorithms/Rust lowest common ancestor](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/graph/lowest_common_ancestor.rs)
