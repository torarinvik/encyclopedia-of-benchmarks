# Biconnected Components

This package decomposes an undirected graph into its maximal vertex-biconnected
blocks. It follows the [Library Checker task](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/graph/biconnected_components/task.md)
and [official limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/graph/biconnected_components/info.toml).
The ports and bounded oracle are clean-room implementations.

## Contract

Input is `[N, M, (u, v)*M]`, with zero-based vertices. Official limits are
`1 <= N <= 500000` and `0 <= M <= 500000`; self-loops are forbidden, while
parallel edges are allowed. The local profile uses `1 <= N <= 6` and
`0 <= M <= 10`. Isolated vertices form singleton blocks. A bridge forms a
two-vertex block. Parallel edges belong to the same block when they join the
same two vertices.

The output is `[K, size_0, vertices..., size_1, vertices..., ...]` as
little-endian unsigned 64-bit values. Each block's vertices are sorted, then
the block lists are sorted lexicographically to make the local output stable;
the official checker accepts any ordering. Invalid input returns `-1`; a null
output or insufficient capacity returns `-2`, and failures write no bytes.

## Algorithm and overlap

The implementation uses a recursive DFS with discovery and low-link values and
an edge stack. When a child's low-link is at least its parent's discovery
number, the stack is popped through that tree edge to form one block. Parent
edge IDs, rather than parent vertices, make the method correct for parallel
edges. The bounded profile has recursion depth at most six and runs in
`O(N + M)` time and space.

The repository already contains `gbbs_biconnectivity`, which also partitions
edges into biconnected blocks but uses the parallel Tarjan–Vishkin method on a
simple-graph profile and returns one edge label per input edge. This package
records vertex sets (including isolated singleton blocks) and uses the
classical DFS low-link edge-stack method, supporting parallel edges. These are
related biconnectivity operations with different methods and output contracts.
The `bridges` and `articulation_points` packages return only cut edges and cut
vertices, respectively.

See [`workload.json`](workload.json) and the
[bounded oracle](../../biconnected_components_oracle.py). No implementation
has been run or compiled.

## Language ports

| Language | Source |
|---|---|
| C | [`c/biconnected_components.c`](../../../c/biconnected_components.c) |
| C3 | [`c3/b/biconnected_components.c3`](../../../c3/b/biconnected_components.c3) |
| C++ | [`cpp/b/biconnected_components.cpp`](../../../cpp/b/biconnected_components.cpp) |
| Elisa | [`elisa/b/biconnected_components.elisa`](../../../elisa/b/biconnected_components.elisa) |
| Nim | [`nim/b/biconnected_components.nim`](../../../nim/b/biconnected_components.nim) |
| Odin | [`odin/b/biconnected_components.odin`](../../../odin/b/biconnected_components.odin) |
| Rust | [`rust/b/biconnected_components.rs`](../../../rust/b/biconnected_components.rs) |
| V | [`v/b/biconnected_components.v`](../../../v/b/biconnected_components.v) |
| Zig | [`zig/b/biconnected_components.zig`](../../../zig/b/biconnected_components.zig) |
| Mojo | [`mojo/b/biconnected_components.mojo`](../../../mojo/b/biconnected_components.mojo) |
