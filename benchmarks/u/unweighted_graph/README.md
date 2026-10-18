# Unweighted Graph

This benchmark measures bounded construction and operation traces for the pinned Ruby `UnweightedGraph`. It preserves directed and undirected adjacency, allows directed edges to name a node that has not been declared yet, and emits neighbor queries in ascending signed-ID order for a stable byte representation.

## Contract

Input is a signed-i64 array:

```text
[directed, initial_node_count, operation_count,
 initial_node_0, ..., initial_node_(n-1),
 op_0, a_0, b_0, ..., op_(m-1), a_(m-1), b_(m-1)]
```

`directed` is 0 for an undirected graph or 1 for a directed graph. There may be 0 through 12 distinct initial node IDs, each a signed 32-bit integer, and 0 through 16 operation records. Input length must be exactly `3 + initial_node_count + 3 * operation_count`; at most 63 words are valid and 64 words are parseable for a trailing-data check.

Each operation is one of:

- `[0, node, 0]`: add a node that does not already exist.
- `[1, start, end]`: add an edge. The start node must exist. The end node must also exist in an undirected graph; a directed graph may store an undeclared end node, matching the source.
- `[2, node, 0]`: query the neighbors of an existing node.

Duplicate initial nodes, duplicate node additions, duplicate edges, unknown query/start nodes, invalid operation records, and out-of-range IDs are outside the valid trace domain and return `-1`. Self-edges are valid and appear once in the neighbor set. Undirected edges appear in both endpoint sets. Directed edges appear only in the start node's set. A later `add_node` for a previously dangling directed neighbor creates that node's own empty neighbor set while retaining the earlier outgoing edge.

Each query contributes `[queried_node, neighbor_count, neighbor_0, ...]` to output. Neighbor IDs are sorted in ascending signed order, independent of the source Set's insertion order. Query records are concatenated in operation order and encoded as little-endian signed-i64 words. Mutations do not emit output. A valid trace with no queries succeeds with zero bytes when the output pointer is non-null.

The output and workspace limit is 648 bytes (81 i64 words). This bound is reachable with seven unique edges followed by nine queries of a node with seven neighbors. Null input or malformed input returns `-1` before output checks. Null output or insufficient capacity returns `-2` after input validation. Errors write no bytes; a null output pointer is an error even when the successful result would be empty.

## Pinned source

- Ruby [`unweighted_graph.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/graphs/unweighted_graph.rb), class `UnweightedGraph`, commit `bda11bdfd83b7958e1ca98247e5e43100ca88865`.

## Workload and oracle

- Workload: [`workload.json`](workload.json)
- Oracle: [`benchmarks/unweighted_graph_oracle.py`](../../unweighted_graph_oracle.py)

## Language ports

| Language | Port |
|---|---|
| C | [`c/u/unweighted_graph.c`](../../../c/u/unweighted_graph.c) |
| C3 | [`c3/u/unweighted_graph.c3`](../../../c3/u/unweighted_graph.c3) |
| C++ | [`cpp/u/unweighted_graph.cpp`](../../../cpp/u/unweighted_graph.cpp) |
| Elisa | [`elisa/u/unweighted_graph.elisa`](../../../elisa/u/unweighted_graph.elisa) |
| Nim | [`nim/u/unweighted_graph.nim`](../../../nim/u/unweighted_graph.nim) |
| Odin | [`odin/u/unweighted_graph.odin`](../../../odin/u/unweighted_graph.odin) |
| Rust | [`rust/u/unweighted_graph.rs`](../../../rust/u/unweighted_graph.rs) |
| V | [`v/u/unweighted_graph.v`](../../../v/u/unweighted_graph.v) |
| Zig | [`zig/u/unweighted_graph.zig`](../../../zig/u/unweighted_graph.zig) |
