# Hamiltonian cycle existence

Decide whether a Hamiltonian cycle exists in a bounded simple undirected graph. The search starts at vertex 0 and backtracks through unvisited adjacent vertices until it has visited every vertex, then checks for an edge back to 0. The result is only an existence flag, so the exact first cycle selected by each pinned implementation does not affect the output.

Pinned sources:

- Java: [TheAlgorithms/Java `HamiltonianCycle.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/graphs/HamiltonianCycle.java)
- Python: [TheAlgorithms/Python `hamiltonian_cycle.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/backtracking/hamiltonian_cycle.py)
- Rust: [TheAlgorithms/Rust `hamiltonian_cycle.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/backtracking/hamiltonian_cycle.rs)

## Contract

Input is a signed 64-bit array `[vertex_count, edge_count, (u, v)...]`. The graph has 3 through 8 vertices, labeled from 0. Every edge is an unordered pair; self-loops and repeated edges are invalid. Vertex 0 is the fixed starting point. Return `1` when a cycle visits each vertex once and returns to 0, `0` when no such cycle exists, and `-1` for malformed input.

The shared domain is deliberately limited to simple undirected graphs. Python and Rust also accept directed adjacency matrices, while the Java implementation removes each selected edge in both directions during its search. Excluding graphs with fewer than three vertices also avoids source-specific behavior: Java special-cases a one-vertex graph and removes the sole edge before checking a two-vertex return edge. The 3-to-8-vertex simple-graph contract preserves the same cycle-existence decision across all three sources.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/h/hamiltonian_cycle_exists.c`](../../../c/h/hamiltonian_cycle_exists.c) |
| C3 | [`c3/h/hamiltonian_cycle_exists.c3`](../../../c3/h/hamiltonian_cycle_exists.c3) |
| C++ | [`cpp/h/hamiltonian_cycle_exists.cpp`](../../../cpp/h/hamiltonian_cycle_exists.cpp) |
| Elisa | [`elisa/h/hamiltonian_cycle_exists.elisa`](../../../elisa/h/hamiltonian_cycle_exists.elisa) |
| Nim | [`nim/h/hamiltonian_cycle_exists.nim`](../../../nim/h/hamiltonian_cycle_exists.nim) |
| Odin | [`odin/h/hamiltonian_cycle_exists.odin`](../../../odin/h/hamiltonian_cycle_exists.odin) |
| Rust | [`rust/h/hamiltonian_cycle_exists.rs`](../../../rust/h/hamiltonian_cycle_exists.rs) |
| V | [`v/h/hamiltonian_cycle_exists.v`](../../../v/h/hamiltonian_cycle_exists.v) |
| Zig | [`zig/h/hamiltonian_cycle_exists.zig`](../../../zig/h/hamiltonian_cycle_exists.zig) |
