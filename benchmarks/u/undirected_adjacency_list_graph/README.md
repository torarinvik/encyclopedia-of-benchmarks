# Undirected Adjacency List Graph

This benchmark replays bounded operations on the pinned Java indexed,
undirected, weighted adjacency-list graph.

## Contract

Input is a signed-i64 array `[operation_count, opcode, a, b, c, ...]`. Each
operation occupies four words: its opcode and three arguments. Unused
arguments must be zero.

| Opcode | Operation | Arguments | Response payload |
|---:|---|---|---|
| `0` | Add node | all zero | New zero-based node index |
| `1` | Add edge | `origin, destination, weight` | `1` if added, `0` otherwise |
| `2` | Get neighbors | `node, 0, 0` | Neighbor count followed by neighbor IDs in ascending order |
| `3` | Get edge weight | `origin, destination, 0` | `[1, weight]` when present; `[0, 0]` when absent (`null`) |
| `4` | Get size | all zero | Current node count |

Each call starts with an empty graph. The graph supports up to 8 indexed nodes
and 24 operations. Node indices and weights fit signed 32-bit integers. An
`add_edge` with an out-of-range endpoint or an existing edge returns false and
does not change the graph. Valid self-edges are accepted; adding the same
self-edge again returns false. A successful edge stores the same weight in
both endpoint adjacency maps. Neighbor results are sorted for deterministic
serialization because the source returns a `HashSet`.

Neighbor queries and edge-weight origins must use node indices that exist at
that point in the operation sequence; an invalid index in either position
would make the Java method throw. An edge-weight destination may be any signed
32-bit integer; a destination without an edge returns the source's `null`
result, represented with a presence flag and a zero placeholder.

Output is a stream of little-endian signed-i64 response records. Each record is
`[opcode, payload_word_count, payload...]`. The response payloads are listed
above. Malformed framing, selectors, arguments, excess nodes, or an invalid
query returns `-1` without writes. A null or undersized output buffer returns
`-2` after the full operation sequence is validated and simulated. Successful
calls return the number of output bytes; output is never partially written.

The maximum input is 97 words; 98 words are parseable to catch trailing data.
The exact maximum output is 144 words (1,152 bytes): six nodes, six accepted
edges connecting a self-looped center to five other nodes, then twelve
neighbor queries of that six-neighbor center.

## Pinned source

- [TheAlgorithms/Java `UndirectedAdjacencyListGraph.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/graphs/UndirectedAdjacencyListGraph.java), commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.

## Workload and oracle

- Workload: [`workload.json`](workload.json)
- Oracle: [`benchmarks/undirected_adjacency_list_graph_oracle.py`](../../undirected_adjacency_list_graph_oracle.py)

## Language ports

| Language | Port |
|---|---|
| C | [`c/u/undirected_adjacency_list_graph.c`](../../../c/u/undirected_adjacency_list_graph.c) |
| C3 | [`c3/u/undirected_adjacency_list_graph.c3`](../../../c3/u/undirected_adjacency_list_graph.c3) |
| C++ | [`cpp/u/undirected_adjacency_list_graph.cpp`](../../../cpp/u/undirected_adjacency_list_graph.cpp) |
| Elisa | [`elisa/u/undirected_adjacency_list_graph.elisa`](../../../elisa/u/undirected_adjacency_list_graph.elisa) |
| Nim | [`nim/u/undirected_adjacency_list_graph.nim`](../../../nim/u/undirected_adjacency_list_graph.nim) |
| Odin | [`odin/u/undirected_adjacency_list_graph.odin`](../../../odin/u/undirected_adjacency_list_graph.odin) |
| Rust | [`rust/u/undirected_adjacency_list_graph.rs`](../../../rust/u/undirected_adjacency_list_graph.rs) |
| V | [`v/u/undirected_adjacency_list_graph.v`](../../../v/u/undirected_adjacency_list_graph.v) |
| Zig | [`zig/u/undirected_adjacency_list_graph.zig`](../../../zig/u/undirected_adjacency_list_graph.zig) |
