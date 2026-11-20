# Network-erosion strength of connection

This package profiles the `i != j` branch of the strength-of-connection
measure in Chapter 598. On a directed graph, it repeatedly finds the shortest
path from a chosen source to target, records that path's length for each
previously unassigned vertex on it, then removes its internal vertices. When
the shortest path is a direct arc, it removes that arc instead. The endpoints
keep the length of their initial shortest path. Vertices never reached by this
erosion retain distance infinity and contribute zero.

## Contract

The exported symbol is `network_erosion_strength_of_connection`; the ABI is
`i64_array_bytes_output`. Input is
`[N,M,source,target,(from,to)*M]`.

- `2 <= N <= 8`, `0 <= M <= N(N-1)`, and the endpoints are distinct IDs in
  `0..N-1`.
- The graph is a simple directed graph without self-loops whose arcs are
  positive and have unit length. The source and target may be disconnected, in
  which case the score is zero. The source measure does not distinguish path
  signs; this profile fixes every arc positive and omits sign labels.
- When shortest paths tie, choose the lexicographically smallest vertex
  sequence. Breadth-first neighbor scans in ascending vertex ID implement this
  rule. The exhaustive reference enumerates simple paths and selects the same
  tie winner independently.
- `d[v]` is the first shortest-path length at which erosion assigns vertex
  `v`; the endpoints retain their initial shortest-path length. The result is
  the exact reduced fraction
  `2/(N+2) * sum(1/d[v])` over finite `d[v]`.
- Output is two little-endian signed 64-bit values `[numerator, denominator]`;
  success returns 16 bytes. Malformed or null input returns `-1`. A null or
  undersized output buffer returns `-2` without writing.
- Maximum valid input length is 116 words; one trailing word, making length
  117, is parseable and rejected.

The package profiles the distinct-endpoint path branch. It omits the chapter's
`source == target` shortest-cycle branch. The book chapter's displayed
normalizers for those branches appear swapped; this profile follows the
original paper's `(N + 2) / 2` normalization for distinct endpoints, which gives a
maximum score of one on a complete directed graph.

## References and overlap

The primary reference uses breadth-first search with a fixed ascending-neighbor
tie order. The independent reference enumerates every simple directed path,
orders candidates by `(edge length, vertex sequence)`, and erodes from that
enumerated path. Both compute the score as an exact rational.

This procedure differs from the repository's [`graph_centrality`](../../g/graph_centrality/README.md),
which computes weighted all-pairs shortest distances once and reports central
and harmonic-closeness nodes. It also differs from connectivity and path
enumeration packages: erosion records the first shortest-path length containing
each vertex as progressively longer routes are exposed.

Sources: Campbell, Thakar, and Albert, [Chapter 598](https://doi.org/10.1007/978-1-4939-2864-4_598)
and the original [Physical Review E paper](https://doi.org/10.1103/PhysRevE.84.031929).
The ports use algorithm descriptions only.

| Language | Source |
|---|---|
| C | [`c/n/network_erosion_strength_of_connection.c`](../../../c/n/network_erosion_strength_of_connection.c) |
| C3 | [`c3/n/network_erosion_strength_of_connection.c3`](../../../c3/n/network_erosion_strength_of_connection.c3) |
| C++ | [`cpp/n/network_erosion_strength_of_connection.cpp`](../../../cpp/n/network_erosion_strength_of_connection.cpp) |
| Elisa | [`elisa/n/network_erosion_strength_of_connection.elisa`](../../../elisa/n/network_erosion_strength_of_connection.elisa) |
| Mojo | [`mojo/n/network_erosion_strength_of_connection.mojo`](../../../mojo/n/network_erosion_strength_of_connection.mojo) |
| Nim | [`nim/n/network_erosion_strength_of_connection.nim`](../../../nim/n/network_erosion_strength_of_connection.nim) |
| Odin | [`odin/n/network_erosion_strength_of_connection.odin`](../../../odin/n/network_erosion_strength_of_connection.odin) |
| Rust | [`rust/n/network_erosion_strength_of_connection.rs`](../../../rust/n/network_erosion_strength_of_connection.rs) |
| V | [`v/n/network_erosion_strength_of_connection.v`](../../../v/n/network_erosion_strength_of_connection.v) |
| Zig | [`zig/n/network_erosion_strength_of_connection.zig`](../../../zig/n/network_erosion_strength_of_connection.zig) |
