# Virtual tree construction

This benchmark compresses a rooted tree to the marked vertices and the LCAs needed to preserve their branching structure. It follows the DFS-order construction described by [OI Wiki's Virtual Tree article](https://oiwiki.net/graph/virtual-tree/). Existing binary-lifting, Tarjan, and Farach–Colton–Bender packages answer LCA queries; this package constructs the compact tree induced by a marked set.

## Contract

The input is `[N,K,parent[1],...,parent[N-1],marked...]`. The root is vertex 0, `1 <= N <= 32`, and `0 <= K <= N`. Each non-root vertex has one in-range parent distinct from itself, and every parent chain must reach 0. Marked vertex IDs must be in range and unique. The exact valid input length is `N+K+1`, at most 65 words; the parser accepts a length field up to 66 to test trailing-word rejection. Malformed input or a null input pointer returns `-1`.

For a nonempty marked set, the virtual vertices are the root, all marked vertices, and the LCAs of adjacent marked vertices after sorting by DFS preorder. Each virtual vertex is connected to its nearest virtual ancestor, with the original tree distance on that compressed edge. `K=0` produces the conventional empty virtual tree, encoded as `[0]`. Otherwise the output is `[V,(vertex,parent_virtual_vertex,distance_to_parent)*V]` in preorder; the root's record is `(0,0,0)`. The result is little-endian signed 64-bit words. Since every virtual vertex comes from the input tree, there are at most 32 records and output is at most 776 bytes. Invalid input takes precedence over output checks; null output or insufficient capacity returns `-2` without writing.

The primary oracle uses adjacent-LCA closure and a stack over DFS order. The independent oracle directly unions all root-to-mark paths and retains their branching vertices, then scans for each nearest retained ancestor. The package is bounded and does not claim the official-scale preprocessing of large trees.

## Provenance and rights

OI Wiki lists the page under CC BY-SA 4.0 and SATA terms. This package uses only the high-level construction for attribution. The implementations, ABI contract, fixtures, and oracles are clean-room work; see [`RIGHTS.md`](RIGHTS.md).

## Language ports

- [C](../../../c/v/virtual_tree.c)
- [C3](../../../c3/v/virtual_tree.c3)
- [C++](../../../cpp/v/virtual_tree.cpp)
- [Elisa](../../../elisa/v/virtual_tree.elisa)
- [Mojo](../../../mojo/v/virtual_tree.mojo)
- [Nim](../../../nim/v/virtual_tree.nim)
- [Odin](../../../odin/v/virtual_tree.odin)
- [Rust](../../../rust/v/virtual_tree.rs)
- [V](../../../v/v/virtual_tree.v)
- [Zig](../../../zig/v/virtual_tree.zig)

The bounded fixtures are in [`workload.json`](workload.json). The package-local static inventory and fixture checker is [`verify_virtual_tree_package.py`](verify_virtual_tree_package.py).
