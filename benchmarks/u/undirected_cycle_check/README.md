# Undirected cycle check

Determine whether a finite undirected graph contains a cycle. The pinned Rust source provides DFS and BFS implementations that track parent vertices; the portable contract normalizes graph labels to integer IDs and uses a bounded adjacency matrix with iterative DFS.

## Contract

- Input is `[vertex_count, edge_count, left_0, right_0, ...]` in the signed 64-bit array ABI.
- The graph has 0–32 vertices and 0–256 edges. The packed array contains exactly two header values and two endpoints per edge.
- Endpoints must be in `[0, vertex_count)`. Duplicate undirected edges are invalid; self-loops are valid and count as a cycle. Edge weights and vertex labels are not part of this unweighted graph contract.
- Return `1` if a cycle exists, `0` otherwise, and `-1` for malformed input.
- The iterative DFS stores the vertex and its parent for each active stack entry. An edge to a visited vertex other than the parent identifies a cycle. Storage is bounded by 32 vertices; the implementation uses portable scalar operations only.

## Workload and verification

[`workload.json`](workload.json) covers empty and singleton graphs, self-loops, trees, disconnected components, cycles, maximum-size inputs, and malformed packed input. The independent oracle uses disjoint-set union. The shared i64-array/scalar verifier exhausts all simple undirected graphs through five vertices.

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm undirected_cycle_check --language c
python3 benchmarks/run_i64_array_scalar.py --algorithm undirected_cycle_check
python3 benchmarks/verify_i64_array_scalar.py --algorithms undirected_cycle_check
```

## Source

- [Rust `detect_cycle.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/graph/detect_cycle.rs)

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/u/undirected_cycle_check.c`](../../../c/u/undirected_cycle_check.c) |
| C3 | [`c3/u/undirected_cycle_check.c3`](../../../c3/u/undirected_cycle_check.c3) |
| C++ | [`cpp/u/undirected_cycle_check.cpp`](../../../cpp/u/undirected_cycle_check.cpp) |
| Elisa | [`elisa/u/undirected_cycle_check.elisa`](../../../elisa/u/undirected_cycle_check.elisa) |
| Nim | [`nim/u/undirected_cycle_check.nim`](../../../nim/u/undirected_cycle_check.nim) |
| Odin | [`odin/u/undirected_cycle_check.odin`](../../../odin/u/undirected_cycle_check.odin) |
| Rust | [`rust/u/undirected_cycle_check.rs`](../../../rust/u/undirected_cycle_check.rs) |
| V | [`v/u/undirected_cycle_check.v`](../../../v/u/undirected_cycle_check.v) |
| Zig | [`zig/u/undirected_cycle_check.zig`](../../../zig/u/undirected_cycle_check.zig) |
