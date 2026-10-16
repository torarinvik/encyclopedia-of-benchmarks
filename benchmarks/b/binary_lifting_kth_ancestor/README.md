# Binary lifting kth ancestor

This package preprocesses a rooted undirected tree and answers batched kth-ancestor queries with binary lifting. It follows the pinned JavaScript source's operation: each query is `[node, k]` and returns the node reached after moving `k` parent links. The source comment mentions LCA as a possible use of binary lifting, but its implementation does not expose an LCA operation; LCA remains covered by [`lowest_common_ancestor_binary_lifting`](../../l/lowest_common_ancestor_binary_lifting/README.md).

Input is `[node_count, root_id, edge_count, query_count, (u, v)..., (node, k)...]` in signed 64-bit slots. Node IDs are `0..node_count-1`; `node_count` is 1 through 256, the graph must be a connected tree with exactly `node_count-1` valid edges, and `query_count` is 0 through 1,024. Query nodes must be valid and `k` must be nonnegative. If `k >= node_count`, the answer is the root, matching the JavaScript method. The input must have exactly the declared number of edge and query slots. Malformed input returns `-1`.

Output is `[query_count, ancestor_0, ancestor_1, ...]` encoded as little-endian signed 64-bit values in query order. A null or undersized output buffer returns `-2`; success returns the output byte length. A zero-query input returns an eight-byte vector containing zero.

| Language | Port |
|---|---|
| C | [`c/b/binary_lifting_kth_ancestor.c`](../../../c/b/binary_lifting_kth_ancestor.c) |
| C3 | [`c3/b/binary_lifting_kth_ancestor.c3`](../../../c3/b/binary_lifting_kth_ancestor.c3) |
| C++ | [`cpp/b/binary_lifting_kth_ancestor.cpp`](../../../cpp/b/binary_lifting_kth_ancestor.cpp) |
| Elisa | [`elisa/b/binary_lifting_kth_ancestor.elisa`](../../../elisa/b/binary_lifting_kth_ancestor.elisa) |
| Nim | [`nim/b/binary_lifting_kth_ancestor.nim`](../../../nim/b/binary_lifting_kth_ancestor.nim) |
| Odin | [`odin/b/binary_lifting_kth_ancestor.odin`](../../../odin/b/binary_lifting_kth_ancestor.odin) |
| Rust | [`rust/b/binary_lifting_kth_ancestor.rs`](../../../rust/b/binary_lifting_kth_ancestor.rs) |
| V | [`v/b/binary_lifting_kth_ancestor.v`](../../../v/b/binary_lifting_kth_ancestor.v) |
| Zig | [`zig/b/binary_lifting_kth_ancestor.zig`](../../../zig/b/binary_lifting_kth_ancestor.zig) |

Pinned source: [TheAlgorithms/JavaScript `Graphs/BinaryLifting.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Graphs/BinaryLifting.js). The benchmark normalizes its `Map`/`Set` tree to bounded integer IDs and excludes the JavaScript module wrapper. See [`workload.json`](workload.json) for representative cases.
