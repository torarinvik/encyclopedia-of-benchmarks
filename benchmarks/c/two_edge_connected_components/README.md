# Two-Edge-Connected Components

This package partitions the vertices of an undirected multigraph into
two-edge-connected components. It follows the [Library Checker task](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/graph/two_edge_connected_components/task.md),
[official limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/graph/two_edge_connected_components/info.toml),
and [checker](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/graph/two_edge_connected_components/checker.cpp).
The ports and bounded oracle are clean-room implementations.

## Contract

Input is `[N, M, (u, v)*M]`, with zero-based vertex IDs. Official limits are
`1 <= N <= 200000` and `1 <= M <= 200000`; parallel edges and self-loops are
allowed. The local profile uses `1 <= N <= 6` and `0 <= M <= 10`, allowing an
empty graph as a small extension. Every vertex appears in exactly one output
component, including isolated vertices and vertices incident only to loops.

The output is `[K, size_0, vertices..., size_1, vertices..., ...]` as
little-endian unsigned 64-bit values. Vertices within each component are sorted,
then component lists are sorted lexicographically for stable local output; the
official checker accepts any order. Since each vertex appears once, the local
maximum is 13 encoded values (104 bytes). Invalid input returns `-1`; null
output or insufficient capacity returns `-2`. Errors write no bytes.

## Algorithm and overlap

The implementation runs Tarjan's discovery/low-link DFS with parent edge IDs
to mark bridges, then floods the graph while skipping those bridges. Using edge
IDs handles parallel edges; loops do not become bridges and do not join any
other vertices. The bounded algorithm takes `O(N + M)` time and space.

The local `bridges` package returns only the bridge edge list. This package
uses the bridge partition as its output. The existing
`two_edge_connected_spanning_subgraph_greedy` constructs one spanning
subgraph, `three_edge_connected_components` uses a stronger connectivity
threshold, and `biconnected_components` partitions by vertex connectivity.
None returns this same vertex partition.

See [`workload.json`](workload.json) and the
[small-graph oracle](../../two_edge_connected_components_oracle.py). No
implementation has been run or compiled.

## Language ports

| Language | Source |
|---|---|
| C | [`c/b/two_edge_connected_components.c`](../../../c/b/two_edge_connected_components.c) |
| C3 | [`c3/t/two_edge_connected_components.c3`](../../../c3/t/two_edge_connected_components.c3) |
| C++ | [`cpp/b/two_edge_connected_components.cpp`](../../../cpp/b/two_edge_connected_components.cpp) |
| Elisa | [`elisa/t/two_edge_connected_components.elisa`](../../../elisa/t/two_edge_connected_components.elisa) |
| Nim | [`nim/t/two_edge_connected_components.nim`](../../../nim/t/two_edge_connected_components.nim) |
| Odin | [`odin/t/two_edge_connected_components.odin`](../../../odin/t/two_edge_connected_components.odin) |
| Rust | [`rust/t/two_edge_connected_components.rs`](../../../rust/t/two_edge_connected_components.rs) |
| V | [`v/t/two_edge_connected_components.v`](../../../v/t/two_edge_connected_components.v) |
| Zig | [`zig/t/two_edge_connected_components.zig`](../../../zig/t/two_edge_connected_components.zig) |
| Mojo | [`mojo/t/two_edge_connected_components.mojo`](../../../mojo/t/two_edge_connected_components.mojo) |

The build and byte-output suite resolve this workload in `c/`; C and C++
sources use the links above, while the other ports use `t/`. This path wiring
has been reviewed statically and has not been run.
