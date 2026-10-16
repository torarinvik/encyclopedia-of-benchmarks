# Check Cycle

Determine whether a directed graph contains a cycle.

## Source

This package follows the pinned [TheAlgorithms/Python `check_cycle`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/check_cycle.py). The source uses depth-first search with a recursion-stack set: an edge to a vertex still on the active path is a cycle; an edge to a completed vertex is not. It checks every graph key, including disconnected components.

## Contract

- ABI: `i64_array_scalar`, with packed input `[vertex_count, edge_count, source_0, destination_0, ...]`.
- Vertices are numbered `0..vertex_count-1`, with `vertex_count` in `0..=32`. Edges are directed; `edge_count` is in `0..=256`, and the array contains exactly `2 + 2 * edge_count` values.
- Every endpoint must name a vertex in the declared range. All declared vertices are graph keys, including vertices with no outgoing edges. Duplicate edges are accepted; they do not change cycle existence.
- Return `1` if a directed cycle exists and `0` otherwise. Invalid bounds, endpoints, or packed length return `-1`.
- Ports use iterative three-color depth-first search, matching the source recursion-stack rule with storage bounded by 32 vertices.

## Workload and oracle

[`workload.json`](workload.json) covers the pinned examples, self-loops, disconnected cycles, cross edges to completed vertices, duplicate edges, maximum bounds, and malformed inputs. The independent oracle uses Kahn's topological-removal algorithm, rather than DFS. Nine ports export `check_cycle` for the shared `i64_array_scalar` runner.

Verify the nine ports against the independent oracle with `python3 benchmarks/verify_i64_array_scalar.py --algorithms check_cycle`.
