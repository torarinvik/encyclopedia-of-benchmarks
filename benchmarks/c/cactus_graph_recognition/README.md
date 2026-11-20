# Cactus graph recognition

This bounded benchmark classifies a simple undirected graph as an edge cactus
and as a vertex cactus, and reports the number of cycles when it is an edge
cactus. An edge cactus has no edge shared by two simple cycles. A vertex cactus
also requires that no vertex belongs to more than one cycle.

## Contract

The `i64_array_scalar` symbol is `cactus_graph_recognition(input, length) ->
i64`. The input is `[N,M,(u,v)*M]`, with vertices labeled `0..N-1`,
`1 <= N <= 32`, and `0 <= M <= 128`. Graphs must be simple, undirected, and
loopless; disconnected graphs are valid. Each unordered edge appears once.
Malformed framing or endpoints return `-1`.

The result packs three fields as `4*C + 2*V + E`: `E` is one for an edge
cactus; `V` is one when each vertex is in at most one cycle; `C` is the cycle
count for edge cacti and zero otherwise. Thus an edgeless graph or tree returns
`3`, a single cycle returns `7`, and an edge cactus with two cycles sharing a
vertex returns `9`.

The primary reference performs iterative depth-first search and assigns each
fundamental cycle the tree edges on its ancestor path. If a tree edge is
claimed by a second cycle, the graph is not an edge cactus. It counts cycle
vertices to classify vertex cacti. The independent reference uses Tarjan's
vertex-biconnected edge blocks: each block must be a bridge or a simple cycle,
then it checks whether cycles share vertices.

## Distinction and source

[`biconnected_components`](../../b/biconnected_components/README.md) reports graph
blocks but does not classify edge and vertex cacti.
[`minimum_cycle_basis_horton`](../../m/minimum_cycle_basis_horton/README.md)
returns a cycle basis, which can contain overlapping cycles even when the
graph's full cycle structure is different. This package instead validates
exclusive cycle-edge ownership and cycle-vertex overlap.

The method idea is described in Sabit Zahin's Algovault
[`cactus.cpp`](https://github.com/sgtlaugh/algovault/blob/bc24742a9b7fba123be5fafca5a93a76bb7f8840/code_library/graphs/cactus.cpp).
The source describes DFS cycle paths, edge and vertex cactus definitions, and
the cactus incidence forest. The local scalar profile measures the recognition
and cycle-count core; it does not emit a cycle listing or cactus forest.
See [`RIGHTS.md`](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [`c/cactus_graph_recognition.c`](../../../c/cactus_graph_recognition.c) |
| C3 | [`c3/cactus_graph_recognition.c3`](../../../c3/cactus_graph_recognition.c3) |
| C++ | [`cpp/cactus_graph_recognition.cpp`](../../../cpp/cactus_graph_recognition.cpp) |
| Elisa | [`elisa/cactus_graph_recognition.elisa`](../../../elisa/cactus_graph_recognition.elisa) |
| Mojo | [`mojo/cactus_graph_recognition.mojo`](../../../mojo/cactus_graph_recognition.mojo) |
| Nim | [`nim/cactus_graph_recognition.nim`](../../../nim/cactus_graph_recognition.nim) |
| Odin | [`odin/cactus_graph_recognition.odin`](../../../odin/cactus_graph_recognition.odin) |
| Rust | [`rust/cactus_graph_recognition.rs`](../../../rust/cactus_graph_recognition.rs) |
| V | [`v/cactus_graph_recognition.v`](../../../v/cactus_graph_recognition.v) |
| Zig | [`zig/cactus_graph_recognition.zig`](../../../zig/cactus_graph_recognition.zig) |

Suite registration: `i64_array_scalar`, symbol
`cactus_graph_recognition`.
