# Long-chain dominant-depth indices

For every vertex of a rooted tree, return the smallest distance at which its
subtree contains the greatest number of vertices. The input is
`[n,parent[1],...,parent[n-1]]`, with `1 <= n <= 64`, root 0, and
`0 <= parent[v] < v`. The output is one little-endian signed i64 depth per
vertex in ID order. A tie between distances selects the shallower distance.

The primary ports use long-chain DP. Each vertex chooses a maximum-height
child, inherits that child's depth-count state shifted by one, then merges
the depth vectors of its other children. The count vectors of vertices on a
long chain share one bounded pool, so all light-vector merges together take
O(n) time and O(n) state. The independent reference directly traverses every
subtree and counts vertices by distance in O(n^2) time.

This is distinct from [`tree_subtree_distinct_sack`](../../t/tree_subtree_distinct_sack/README.md),
which uses the largest-subtree child to count distinct labels with DSU-on-tree,
and from heavy-light path-query profiles, which use subtree size to build path
chains. The source for algorithm identification and its mathematical method is
the [OI Wiki long-chain decomposition section](https://oi-wiki.org/graph/hld/).
The profile's vertex numbering, tie rules, limits, ABI, and fixtures are
specified here and in `workload.json`; all ports and fixtures are clean-room.
OI Wiki states its default content terms as CC BY-SA 4.0 and SATA in its
[FAQ](https://oi-wiki.org/intro/faq/).

On success, the function returns the number of bytes written (`8*n`). Invalid
input returns `-1`. A null or short output buffer returns `-2` without writing.
Maximum output is 512 bytes and the fixed workspace cap is 8,192 bytes.

| Language | Port |
|---|---|
| C | [c/l/long_chain_dominant_depth_index.c](../../../c/l/long_chain_dominant_depth_index.c) |
| C3 | [c3/l/long_chain_dominant_depth_index.c3](../../../c3/l/long_chain_dominant_depth_index.c3) |
| C++ | [cpp/l/long_chain_dominant_depth_index.cpp](../../../cpp/l/long_chain_dominant_depth_index.cpp) |
| Elisa | [elisa/l/long_chain_dominant_depth_index.elisa](../../../elisa/l/long_chain_dominant_depth_index.elisa) |
| Mojo | [mojo/l/long_chain_dominant_depth_index.mojo](../../../mojo/l/long_chain_dominant_depth_index.mojo) |
| Nim | [nim/l/long_chain_dominant_depth_index.nim](../../../nim/l/long_chain_dominant_depth_index.nim) |
| Odin | [odin/l/long_chain_dominant_depth_index.odin](../../../odin/l/long_chain_dominant_depth_index.odin) |
| Rust | [rust/l/long_chain_dominant_depth_index.rs](../../../rust/l/long_chain_dominant_depth_index.rs) |
| V | [v/l/long_chain_dominant_depth_index.v](../../../v/l/long_chain_dominant_depth_index.v) |
| Zig | [zig/l/long_chain_dominant_depth_index.zig](../../../zig/l/long_chain_dominant_depth_index.zig) |

The `i64_array_bytes_output` runner and verifier registration is integrated.
