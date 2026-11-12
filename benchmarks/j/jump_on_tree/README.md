# Jump on a tree

Given an undirected tree and queries `(s,t,k)`, return the vertex reached after
walking `k` edges from `s` toward `t` along their unique path. Return `-1` when
`k` is beyond that path. Each query finds the LCA, compares the requested jump
with the distance from `s` to the LCA, and lifts the appropriate endpoint by
binary ancestors.

## Contract

The bounded ABI encodes `[N,Q,(u,v)...,(s,t,k)...]`, with `2 <= N <= 64` and
`1 <= Q <= 64`. The first `N-1` edges must form a tree; query endpoints and
`k` must be in `[0,N)`. A successful call writes one signed 64-bit
little-endian value per query. Invalid input returns `-1`; a null or
undersized output buffer returns `-2` without writing. The maximum input is
320 integers and the maximum output/workspace is 512 bytes. Here
`workspace.bytes=512` is the output-buffer capacity; tree and ancestor tables
use separate local storage.

## Distinctness

[`lowest_common_ancestor_binary_lifting`](../../l/lowest_common_ancestor_binary_lifting/README.md)
returns only the LCA of each endpoint pair. This workload returns the kth
vertex on the ordered path and reports when the requested index is outside
that path. It shares binary-lifting preprocessing but measures a different
query result and path-position calculation.

Official contract: [Library Checker — Jump on Tree](https://github.com/yosupo06/library-checker-problems/blob/master/tree/jump_on_tree/task.md)
with bounds from its [info.toml](https://github.com/yosupo06/library-checker-problems/blob/master/tree/jump_on_tree/info.toml).

## Workload and oracle

[`workload.json`](workload.json) covers forward and reverse jumps, endpoint
queries, same-vertex paths, out-of-path indices, malformed trees, invalid
queries, and insufficient capacity. The independent
[`benchmarks/jump_on_tree_oracle.py`](../../jump_on_tree_oracle.py) finds each
path directly with breadth-first search.

## Implementations

| Language | Port |
|---|---|
| C | [`c/j/jump_on_tree.c`](../../../c/j/jump_on_tree.c) |
| C3 | [`c3/j/jump_on_tree.c3`](../../../c3/j/jump_on_tree.c3) |
| C++ | [`cpp/j/jump_on_tree.cpp`](../../../cpp/j/jump_on_tree.cpp) |
| Elisa | [`elisa/j/jump_on_tree.elisa`](../../../elisa/j/jump_on_tree.elisa) |
| Nim | [`nim/j/jump_on_tree.nim`](../../../nim/j/jump_on_tree.nim) |
| Odin | [`odin/j/jump_on_tree.odin`](../../../odin/j/jump_on_tree.odin) |
| Rust | [`rust/j/jump_on_tree.rs`](../../../rust/j/jump_on_tree.rs) |
| V | [`v/j/jump_on_tree.v`](../../../v/j/jump_on_tree.v) |
| Zig | [`zig/j/jump_on_tree.zig`](../../../zig/j/jump_on_tree.zig) |
| Mojo | [`mojo/j/jump_on_tree.mojo`](../../../mojo/j/jump_on_tree.mojo) |
