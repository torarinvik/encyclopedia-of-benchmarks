# Predecessor-constrained DFS

Run the recursive predecessor-constrained depth-first traversal from [TheAlgorithms Java `PredecessorConstrainedDfs.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/graph/PredecessorConstrainedDfs.java). The traversal visits the start node immediately, then scans outgoing neighbors in ascending node order. It recurses into an unvisited neighbor only when all of that node's predecessors have already been visited. Otherwise it emits a SKIP event and leaves the node unvisited so a later predecessor can make it eligible.

The `i64_array_bytes_output` ABI packs input as `[n, start, adjacency_bits_row_major...]`. The `n × n` matrix is directed; a `1` at row `u`, column `v` means edge `u → v`. A VISIT event is encoded as `(1, node, zero_based_visit_order)` and a SKIP event as `(0, node, -1)`, with each field serialized as little-endian signed i32. The source's skip note is represented by the event type and node.

## Bounds and invalid inputs

- `1 <= n <= 16`, vertices are zero-based, and the exact input length is `2 + n*n` (at most 258 signed-i64 values).
- Matrix entries must be `0` or `1`, diagonal entries must be `0`, and the directed graph must be acyclic. The graph may be disconnected; only nodes reached from `start` produce events.
- At most 136 events are possible, so the output buffer is bounded to 1,632 bytes.
- Malformed input, a self-edge, or a cycle returns `-1`. A null output or insufficient output capacity returns `-2` without writing output.

The workload uses the `i64_array_bytes_output` ABI and `i64_array_bytes_output_call` comparison model.
