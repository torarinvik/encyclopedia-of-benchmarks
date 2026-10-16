# Reflexive transitive closure matrix

Compute directed reachability with the Floyd-Warshall method. This package follows the pinned Python implementation, which copies the adjacency matrix, sets every diagonal entry to 1, and then considers each vertex as an intermediate point. The benchmark wrapper accepts an edge list and builds the corresponding 0/1 adjacency matrix before applying those semantics.

Pinned sources:

- Python: [TheAlgorithms/Python `transitive_closure.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/matrix/transitive_closure.py)
- C: [TheAlgorithms/C `transitive_closure.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/graphs/transitive_closure.c)

The C source is a fixed 4×4 demonstration graph and does not force reflexive diagonal entries. It is documented here as a related implementation, but it does not define this general graph contract.

## Contract

Input is a signed 64-bit array `[vertex_count, edge_count, (from_vertex, to_vertex)...]`. The vertex count is 1 through 32. Vertices use zero-based IDs. Edges are directed; self-loops and duplicate ordered pairs are rejected. The edge count can be 0 through `vertex_count * (vertex_count - 1)`.

The closure matrix starts with all diagonal entries set to 1 and each listed edge set to 1. Floyd-Warshall then adds reachability through intermediate vertices, in the pinned Python loop order. Output is the `vertex_count × vertex_count` matrix in row-major order, with each 0 or 1 encoded as a little-endian signed 64-bit integer. The function returns the output byte count, `-1` for malformed input, and `-2` for a null or undersized output buffer.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/t/transitive_closure_reflexive_matrix.c`](../../../c/t/transitive_closure_reflexive_matrix.c) |
| C3 | [`c3/t/transitive_closure_reflexive_matrix.c3`](../../../c3/t/transitive_closure_reflexive_matrix.c3) |
| C++ | [`cpp/t/transitive_closure_reflexive_matrix.cpp`](../../../cpp/t/transitive_closure_reflexive_matrix.cpp) |
| Elisa | [`elisa/t/transitive_closure_reflexive_matrix.elisa`](../../../elisa/t/transitive_closure_reflexive_matrix.elisa) |
| Nim | [`nim/t/transitive_closure_reflexive_matrix.nim`](../../../nim/t/transitive_closure_reflexive_matrix.nim) |
| Odin | [`odin/t/transitive_closure_reflexive_matrix.odin`](../../../odin/t/transitive_closure_reflexive_matrix.odin) |
| Rust | [`rust/t/transitive_closure_reflexive_matrix.rs`](../../../rust/t/transitive_closure_reflexive_matrix.rs) |
| V | [`v/t/transitive_closure_reflexive_matrix.v`](../../../v/t/transitive_closure_reflexive_matrix.v) |
| Zig | [`zig/t/transitive_closure_reflexive_matrix.zig`](../../../zig/t/transitive_closure_reflexive_matrix.zig) |
