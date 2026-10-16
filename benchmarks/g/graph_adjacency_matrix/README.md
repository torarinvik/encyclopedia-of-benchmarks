# Adjacency-matrix graph ADT trace

This benchmark captures the bounded operations of TheAlgorithms/Python's `GraphAdjacencyMatrix`. It measures topology updates and membership queries while returning the final vertex order and matrix.

## Contract

- Input is `[directed, vertex_count, vertex_ids..., edge_count, (from,to)..., operation_count, (operation,a,b)...]` as signed 64-bit integers. `directed` is 1 or 0. Vertex IDs are unique integers in `[0,31]`; at most 8 vertices, 64 initial edges, and 24 operations are accepted. The label range stays wider than the active-vertex bound so traces can use sparse IDs.
- Operation `0` adds vertex `a`; `1` removes vertex `a`; `2` adds edge `a -> b`; `3` removes edge `a -> b`; `4` tests whether vertex `a` exists; `5` tests whether edge `a -> b` exists; `6` clears the graph. Unary operations require `b=0`; clear requires both arguments zero.
- Edges must refer to existing vertices and may not repeat. Undirected edges update both matrix cells; adding the reverse of an existing undirected edge is a duplicate. Self-loops are supported. Removing a vertex compacts the vertex order and corresponding matrix row and column; adding a vertex appends it at the end.
- Any malformed operation, duplicate vertex or edge, missing required vertex, or missing edge returns `-1`. Missing or undersized output storage returns `-2` without writing. This maps the source's `ValueError` cases to a deterministic benchmark error code.
- Output is a little-endian signed 64-bit vector `[operation_count, result_per_operation..., final_vertex_count, vertex_ids..., adjacency_matrix_row_major...]`. Mutations return 1, and membership queries return 0 or 1. Matrix rows and columns follow the final vertex insertion order.

The contract uses integer labels in place of the source's generic hashable Python vertices. It excludes exception text and `__repr__` formatting. The maximum output is 98 signed 64-bit words (784 bytes).

[`workload.json`](workload.json) covers directed and undirected updates, matrix symmetry, vertex removal and reindexing, clear/reinsert, self-loops, queries, and invalid operations. Record measurements with [`benchmarks/run_i64_array_bytes_output.py`](../../run_i64_array_bytes_output.py) and check the ports with [`benchmarks/verify_i64_array_bytes_output.py`](../../verify_i64_array_bytes_output.py):

```sh
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm graph_adjacency_matrix
```

## Pinned source

- [TheAlgorithms/Python `graph_adjacency_matrix.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/graph_adjacency_matrix.py)
