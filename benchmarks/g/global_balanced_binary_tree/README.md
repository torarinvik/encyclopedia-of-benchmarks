# Global balanced binary tree construction

This bounded profile constructs the static globally balanced binary-tree
forest for a rooted tree and returns a structural checksum. Each original
heavy path becomes one binary-search tree; its root is joined to the original
parent of that path's head. The weighted midpoint uses each path vertex's
weight `subtree_size[v] - subtree_size[heavy_child[v]]`.

## Contract

- ABI: `i64_array_scalar`.
- Input is `[n, parent[1], ..., parent[n-1]]`. Vertex 0 is the root. There are
  `1 <= n <= 64` vertices, and `0 <= parent[v] < v` for every `v > 0`.
  Therefore the parent list describes one rooted tree and the exact input
  length is `n`. Maximum valid and parseable lengths are 64 and 65 i64 values.
- The heavy child is the child with the largest rooted subtree. Equal subtree
  sizes choose the smaller vertex ID.
- A heavy path is ordered from its head toward its heavy child. For a local
  interval `[lo,hi)`, choose the rightmost pivot whose preceding weight is at
  most half the interval's total weight. This fixes midpoint ties; recursively
  build the left and right intervals as the pivot's children. The local BST
  subtree size stored for the pivot is `hi-lo`.
- OI Wiki's construction examples differ on an exact-half tie. This profile
  pins the rightmost-predecessor rule from the English construction so every
  port emits the same deterministic structure.
- A local BST root's forest parent is the original parent of its heavy-path
  head, or `-1` for the root path. A non-root local BST node's forest parent
  is its local BST parent. Missing left/right children are `-1`.
- For each vertex, encode its GBST parent, left child, and right child by
  adding one (`-1` becomes zero), then form
  `record = parent_code + 65*left_code + 65^2*right_code + 65^3*local_size`.
  Return `sum((vertex_id+1)*record)` over all vertices. The result is at most
  37,129,297,920 and fits signed 64-bit. Malformed input returns `-1`.
- The construction uses fixed arrays for at most 64 vertices. Its tree-local
  midpoint recursion has at most 64 active frames. The fixed node and prefix
  buffers contain 577 integer slots in total (at most 4,616 bytes when slots
  are 64 bits), excluding recursion frames and the input. The profile
  deliberately measures the static forest build and does not implement
  dynamic path tags or matrix-DP updates.

The weighted heavy-path forest is distinct from ordinary heavy-light metadata:
it adds a weighted-midpoint binary tree within each heavy path and links those
local roots across light edges. It is also distinct from link-cut trees and
dynamic top trees, whose represented structure changes during operations.

## References

- [OI Wiki English: Globally Balanced Binary Tree](https://www.timothywang.ca/OI-wiki/ds/global-bst/)
  describes heavy-path contributions, weighted-midpoint construction, and
  the connected forest representation.
- [OI Wiki Chinese: 全局平衡二叉树](https://oiwiki.wiki/ds/global-bst/)
  gives a separate implementation example and discusses path-query use.

The references supply algorithm descriptions only. The contract, deterministic
tie rules, checksum, workload, oracles, and language ports are independently
written. The `i64_array_scalar` runner/verifier dispatch is registered in
source; no programs or checks were run. See [RIGHTS.md](RIGHTS.md),
[workload.json](workload.json), and [INVENTORY.md](INVENTORY.md).
