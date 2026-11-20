# Undirected Eulerian trail with Hierholzer traversal

This draft constructs an edge-covering trail in an undirected multigraph,
including loops and parallel edges, using a stack and one used flag per edge.
It is distinct from the directed `eulerian_path` benchmark and from
`eulerian_trail_undirected_simple`, which preserves a source-specific DFS
discovery sequence that need not be a trail.

## Contract

The `i64_array_bytes_output` input is `[n,m,u0,v0,...]`, with `1 <= n <= 16`,
`0 <= m <= 32`, and endpoints in `[0,n)`. Edges retain input order and may
repeat or be loops. Select the smallest odd-degree vertex when there are two,
otherwise the smallest incident vertex; for an empty graph select vertex 0.
At each stack step consume the next unused incident edge in input order.
Append a vertex when it has no unused edge, then reverse that list. If the
odd-degree count is neither zero nor two, or if not all edges are consumed,
return 0 with no output. Otherwise emit the `m+1` vertices as little-endian
signed 64-bit values and return their byte count. Malformed input returns -1;
null or insufficient output for a valid trail returns -2 without writes.
Input validation takes precedence over output checks; graphs without a trail
return 0 without using the output buffer, even when it is null or has zero
capacity.
Maximum valid and parseable input lengths are 66 and 67 words; maximum output
is 264 bytes. Traversal performs O(n+m) work using edge-ID adjacency lists.
The fixed port arrays reserve a 16-by-64 adjacency table, so their storage is
bounded by the product of the vertex and edge limits rather than a compact
O(n+m) allocation; some drafts also initialize the whole table. The workload's
16384-byte workspace is the suite's output-buffer capacity, not a caller-supplied
scratch arena.

## Provenance and status

The algorithm idea follows [CP-Algorithms: Finding the Eulerian path](https://cp-algorithms.com/graph/euler_path.html)
and the pinned [TheAlgorithms/Java Hierholzer implementation](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/graph/HierholzerAlgorithm.java).
CP-Algorithms uses CC BY-SA 4.0 and the Java repository uses MIT; only algorithm
ideas are used here. The contract and code are independently written.

The ten language drafts, [primary reference](oracle.py), [recursive independent
reference](independent_oracle.py), and [workload](workload.json) are present.
The byte-output runner and verifier have draft registration and bounds checks.
The verifier draft also checks successful small outputs against the input edge
multiset, including loops and repeated edges, independently of traversal order.
All remain uncompiled and unexecuted, so correctness and integration are not
yet verified.
