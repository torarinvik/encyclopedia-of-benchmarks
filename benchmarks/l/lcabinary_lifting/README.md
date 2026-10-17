# Lowest common ancestor by binary lifting

This benchmark follows the JavaScript `lcaBinaryLifting` function and its
`BinaryLifting` helper on a bounded rooted tree. It answers a sequence of
lowest-common-ancestor queries and returns a weighted checksum of node IDs.

## Contract

The `i64_array_scalar` input is
`[node_count, root, edge_count, (u, v) * edge_count, query_count, (u, v) * query_count]`.
There are 2 through 128 nodes, numbered `0` through `node_count - 1`, and at
most 256 queries. The edge count must be `node_count - 1`; edges are undirected,
non-self, unique, and must form one connected tree. `root` must be a node in
that tree. Every query endpoint must also be in range.

For query `i` in zero-based order, let `a` be its lowest common ancestor under
the selected root. The result adds `(i + 1) * (a + 1)` to the checksum. With no
queries the result is zero. Invalid counts, endpoints, framing, disconnected
or cyclic edge sets, duplicate edges, and trailing values return `-1`.

The tree-size lower bound excludes the helper's empty-graph path, which creates
no adjacency-map entry for the root. A valid tree makes the source's recursive
parent traversal safe and ensures every node receives a depth and ancestor
table. The source sets the root's immediate parent to itself, uses
`ceil(log2(node_count))` binary-lifting levels, first raises the deeper query
node, then raises both nodes from the highest stored level down.

The maximum valid frame contains 770 integers; the maximum parseable frame
contains 771. The scalar output is always nonnegative for valid input and
cannot collide with invalid result `-1`.

## Pinned sources

- TheAlgorithms/JavaScript [`LCABinaryLifting.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Graphs/LCABinaryLifting.js), commit `5c39e87a9a31f279c60f830ad74a845e4788a517`
- The helper it extends, [`BinaryLifting.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Graphs/BinaryLifting.js), same commit

## Workload

The workload is [`workload.json`](workload.json); the independent parent-walk
oracle is [`benchmarks/lcabinary_lifting_oracle.py`](../../lcabinary_lifting_oracle.py).
