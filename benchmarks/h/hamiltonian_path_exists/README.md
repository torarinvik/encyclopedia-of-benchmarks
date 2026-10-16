# Hamiltonian path existence

Determine whether a directed graph contains a path that visits each vertex exactly once.

## Contract

- The `i64_array_scalar` input is `[vertex_count, row-major adjacency matrix cells...]`, with 0 through 8 vertices. A cell is `1` when the directed edge from its row vertex to its column vertex exists, and `0` otherwise.
- The packed length must be exactly `1 + vertex_count * vertex_count`.
- Return `1` when a Hamiltonian path exists, `0` when it does not, and `-1` for malformed input. The empty graph returns `0`; a one-vertex graph returns `1`.

## Source semantics

The pinned C++ function is named `hamilton_cycle`, but its dynamic program returns true if any endpoint is reachable after visiting every vertex. It does not check an edge back to the start, so it computes Hamiltonian path existence. [Pinned source](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/graph/hamiltons_cycle.cpp). The additional C++ repository copy contains the same algorithm.

[`workload.json`](workload.json) covers empty and singleton graphs, directed chains and cycles, disconnected graphs, the eight-vertex limit, and malformed matrices.

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm hamiltonian_path_exists --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/h/hamiltonian_path_exists/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/h/hamiltonian_path_exists.c`](../../../c/h/hamiltonian_path_exists.c) |
| C3 | [`c3/h/hamiltonian_path_exists.c3`](../../../c3/h/hamiltonian_path_exists.c3) |
| C++ | [`cpp/h/hamiltonian_path_exists.cpp`](../../../cpp/h/hamiltonian_path_exists.cpp) |
| Elisa | [`elisa/h/hamiltonian_path_exists.elisa`](../../../elisa/h/hamiltonian_path_exists.elisa) |
| Nim | [`nim/h/hamiltonian_path_exists.nim`](../../../nim/h/hamiltonian_path_exists.nim) |
| Odin | [`odin/h/hamiltonian_path_exists.odin`](../../../odin/h/hamiltonian_path_exists.odin) |
| Rust | [`rust/h/hamiltonian_path_exists.rs`](../../../rust/h/hamiltonian_path_exists.rs) |
| V | [`v/h/hamiltonian_path_exists.v`](../../../v/h/hamiltonian_path_exists.v) |
| Zig | [`zig/h/hamiltonian_path_exists.zig`](../../../zig/h/hamiltonian_path_exists.zig) |
