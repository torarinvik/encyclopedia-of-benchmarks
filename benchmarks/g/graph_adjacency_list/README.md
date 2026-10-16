# Adjacency-list graph ADT trace

This benchmark captures the bounded operations of TheAlgorithms/Python's generic `GraphAdjacencyList`. It models topology updates and membership queries; it does not benchmark a graph traversal.

## Contract

- Input is a signed 64-bit vector `[directed, vertex_count, vertex_ids..., edge_count, (from,to)..., operation_count, (operation,a,b)...]`.
- `directed` is `1` for directed edges and `0` for undirected edges. Initial vertices and later vertex IDs are unique integers in `[0,31]`; at most 32 vertices are active. Initial edges must reference existing vertices and must be unique. There are at most 1,024 initial edge records and 64 operations.
- Operation `0` adds vertex `a`; `1` removes vertex `a`; `2` adds edge `a -> b`; `3` removes edge `a -> b`; `4` tests whether vertex `a` exists; `5` tests whether edge `a -> b` exists; `6` clears the graph. Unary operations require `b=0`; clear requires `a=b=0`.
- Duplicate vertices/edges, unknown vertices, missing edges, malformed fields, or out-of-range IDs return `-1`, matching the source's rejected operations. Null or insufficient output storage returns `-2` without writing.
- Successful output is a little-endian signed 64-bit vector `[operation_count, result_per_operation..., final_vertex_count, (vertex_id,neighbor_count,neighbor_ids...)*]`. Mutation results are `1`; membership queries return `0` or `1`. Vertex rows follow vertex insertion order, and each neighbor row follows edge insertion order.
- Undirected edge insertion appends the reverse neighbor as well. An undirected self-loop is therefore stored twice in its row, as in the source. Removing that self-loop removes both entries. Vertex removal also removes all incoming and outgoing references; adding a previously removed vertex places it at the end of insertion order. `clear_graph` removes all vertices but preserves directedness.

The fixed limits cap recursion/storage and keep the trace deterministic. The source accepts arbitrary hashable Python labels; this contract uses dense bounded integer labels. It omits `__repr__` formatting and exception message text.

[`workload.json`](workload.json) covers directed and undirected traces, ordering, self-loops, vertex lifecycle, clear/reinsert, and invalid operations.

Build with the shared `i64_array_bytes_output` ABI. Record measurements with [`benchmarks/run_i64_array_bytes_output.py`](../../run_i64_array_bytes_output.py) and check the nine ports against the independent oracle with [`benchmarks/verify_i64_array_bytes_output.py`](../../verify_i64_array_bytes_output.py):

```sh
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm graph_adjacency_list
```

## Pinned source

- [TheAlgorithms/Python `graph_adjacency_list.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/graph_adjacency_list.py)
- The JavaScript [`Graph2.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Graph/Graph2.js) construction methods map to this contract for valid, unique vertices and edges; its printed representation is normalized to the ordered adjacency rows.
