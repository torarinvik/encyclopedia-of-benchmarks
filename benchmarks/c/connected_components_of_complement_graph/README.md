# Connected components of the complement graph

Given a simple undirected graph `G`, decompose its complement into connected
components. The implementation keeps an unvisited-vertex list. For each
vertex removed from the BFS queue, it marks neighbors in `G`; every still
unvisited unmarked vertex is adjacent in the complement and joins the current
component. After labeling, the ABI canonicalizes components by their smallest
vertex and lists vertices in ascending order.

## Contract

The official input contains `N M` followed by `M` undirected edges. `G` must
be simple. The output is the number of complement components, followed by
each component's size and its vertices. The official limits are
`1 <= N <= 500000` and `0 <= M <= 500000`.

The bounded ABI uses `[N,M,(u,v)...]`, with `1 <= N <= 64` and at most
`N*(N-1)/2` edges. Self-loops, duplicate edges, invalid endpoints, and
malformed lengths return `-1`. Successful calls write a canonical partition as
signed 64-bit little-endian integers and return the number of bytes written.
A null or undersized output buffer returns `-2` without writing. At most
`1+2*N` output integers are required, so `workspace.bytes=1032` is the maximum
output-buffer capacity; adjacency and traversal storage are separate.

## Distinctness

The local [`connected_components`](../connected_components/README.md) and
[`connected_components_with_dsu`](../connected_components_with_dsu/README.md)
packages decompose the supplied graph itself. This benchmark searches the
implicit complement graph and uses the unvisited-list/neighbor-marking
algorithm, so it is a distinct traversal workload.

Official contract: [Library Checker — Connected Components of Complement Graph](https://github.com/yosupo06/library-checker-problems/blob/master/graph/connected_components_of_complement_graph/task.md)
with limits from its [info.toml](https://github.com/yosupo06/library-checker-problems/blob/master/graph/connected_components_of_complement_graph/info.toml).

## Workload and oracle

[`workload.json`](workload.json) covers an empty input graph, a complete graph,
a path, a star, duplicate-edge rejection, and insufficient output capacity.
The independent [`benchmarks/connected_components_of_complement_graph_oracle.py`](../../connected_components_of_complement_graph_oracle.py)
builds and traverses the complement graph directly.

## Implementations

| Language | Port |
|---|---|
| C | [`c/c/connected_components_of_complement_graph.c`](../../../c/c/connected_components_of_complement_graph.c) |
| C3 | [`c3/c/connected_components_of_complement_graph.c3`](../../../c3/c/connected_components_of_complement_graph.c3) |
| C++ | [`cpp/c/connected_components_of_complement_graph.cpp`](../../../cpp/c/connected_components_of_complement_graph.cpp) |
| Elisa | [`elisa/c/connected_components_of_complement_graph.elisa`](../../../elisa/c/connected_components_of_complement_graph.elisa) |
| Nim | [`nim/c/connected_components_of_complement_graph.nim`](../../../nim/c/connected_components_of_complement_graph.nim) |
| Odin | [`odin/c/connected_components_of_complement_graph.odin`](../../../odin/c/connected_components_of_complement_graph.odin) |
| Rust | [`rust/c/connected_components_of_complement_graph.rs`](../../../rust/c/connected_components_of_complement_graph.rs) |
| V | [`v/c/connected_components_of_complement_graph.v`](../../../v/c/connected_components_of_complement_graph.v) |
| Zig | [`zig/c/connected_components_of_complement_graph.zig`](../../../zig/c/connected_components_of_complement_graph.zig) |
| Mojo | [`mojo/c/connected_components_of_complement_graph.mojo`](../../../mojo/c/connected_components_of_complement_graph.mojo) |
