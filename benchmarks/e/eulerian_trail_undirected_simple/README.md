# Eulerian trail in a simple undirected graph

This package preserves the pinned Python implementation's edge-marking depth-first discovery order and start-node rules: circuits start at vertex 1, while an open case starts at the highest-labeled odd-degree vertex. Each adjacency list follows the input edge order. The routine appends a vertex on entry and does not splice cycles during backtracking, so its returned sequence is not guaranteed to be an Eulerian trail even when one exists.

Input is `[vertex_count, edge_count, u0, v0, ...]` in signed 64-bit slots. `vertex_count` is 2 through 10, labels are in `[0, vertex_count)`, and `edge_count` is 0 through 45. The input must contain exactly two endpoint slots per edge. Self-loops, duplicate undirected edges, disconnected nonzero-degree vertices, and graphs with an odd-degree count other than 0 or 2 are invalid. For a nonempty circuit, vertex 1 must be incident to an edge. The empty-edge case returns the one-vertex circuit `[1]`.

The 45-edge input limit permits parsing a complete ten-vertex graph, which is
invalid because all ten degrees are odd. The largest valid graph has 41 edges:
remove four disjoint edges from the complete graph, leaving two odd vertices.
Thus valid input has at most 84 words and valid output at most 352 bytes; the
suite reserves conservative bounds of 93 parseable words and 384 output bytes.

Output is `[status, vertex_count, discovery_vertices...]` encoded as little-endian signed 64-bit values. Status `1` identifies the even-degree case; status `2` identifies the two-odd-degree case. For example, with edges `(0,3), (0,1), (0,2), (2,4), (0,4)`, the routine starts at 3 and emits `3,0,1,2,4,0`; vertices 1 and 2 are not adjacent. Invalid input returns `-1`; a null or undersized output buffer returns `-2`. The return value on success is the number of output bytes.

Input validation precedes output-buffer checks: malformed input returns `-1`
even when the output pointer is null or the capacity is too small. Errors do
not write output.

Each entry into a vertex scans its entire adjacency list again, including
already marked edges. For vertex degrees `d(v)`, traversal takes
`O(n + m + sum(d(v)^2))` time, bounded by `O(n + nm)` for a simple graph.
The fixed port arrays reserve `O(nm + n²)` slots in this bounded profile,
and recursive or explicit traversal can reach `O(m)` frames. These bounds
describe this discovery-order routine, not a linear-time Hierholzer traversal.

The byte-output runner's reference follows the same discovery-order contract.
An [independent iterative reference](independent_oracle.py) and verifier
registration draft cover small simple graphs in both edge orders, null and
short buffers, the cycle-splicing counterexample, and a maximum 41-edge
two-odd-vertex graph. The references, registration, and fixtures remain unexecuted.

| Language | Port |
|---|---|
| C | [`c/e/eulerian_trail_undirected_simple.c`](../../../c/e/eulerian_trail_undirected_simple.c) |
| C3 | [`c3/e/eulerian_trail_undirected_simple.c3`](../../../c3/e/eulerian_trail_undirected_simple.c3) |
| C++ | [`cpp/e/eulerian_trail_undirected_simple.cpp`](../../../cpp/e/eulerian_trail_undirected_simple.cpp) |
| Elisa | [`elisa/e/eulerian_trail_undirected_simple.elisa`](../../../elisa/e/eulerian_trail_undirected_simple.elisa) |
| Mojo | [`mojo/e/eulerian_trail_undirected_simple.mojo`](../../../mojo/e/eulerian_trail_undirected_simple.mojo) |
| Nim | [`nim/e/eulerian_trail_undirected_simple.nim`](../../../nim/e/eulerian_trail_undirected_simple.nim) |
| Odin | [`odin/e/eulerian_trail_undirected_simple.odin`](../../../odin/e/eulerian_trail_undirected_simple.odin) |
| Rust | [`rust/e/eulerian_trail_undirected_simple.rs`](../../../rust/e/eulerian_trail_undirected_simple.rs) |
| V | [`v/e/eulerian_trail_undirected_simple.v`](../../../v/e/eulerian_trail_undirected_simple.v) |
| Zig | [`zig/e/eulerian_trail_undirected_simple.zig`](../../../zig/e/eulerian_trail_undirected_simple.zig) |

Pinned sources: [TheAlgorithms/Python `eulerian_path_and_circuit_for_undirected_graph.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/eulerian_path_and_circuit_for_undirected_graph.py) and [TheAlgorithms/Java `HierholzerAlgorithm.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/graph/HierholzerAlgorithm.java). The benchmark follows the Python routine's discovery order; it does not implement Hierholzer's cycle-splicing output. The Java source is circuit-only and supports multigraph edges. The Python source's printed wrapper is excluded. See [`workload.json`](workload.json) for representative cases.
