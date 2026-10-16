# Directed Simple Cycles

This package ports the deterministic DFS enumerator inside the pinned Java [`Cycles.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/graphs/Cycles.java). The source wraps it in an interactive console; the benchmark exposes its graph traversal as a call and omits prompts and printing. It enumerates directed simple cycles, including self-loops, in ascending start-vertex and adjacency-matrix DFS order. After processing each start vertex, it clears all incoming and outgoing arcs at that vertex, so each cycle is emitted once from its lowest-numbered vertex.

## Contract

- Input is `[vertex_count, edge_count, source_0, destination_0, ...]` in the signed 64-bit array ABI. The graph is directed, has at most 6 vertices and 36 arcs, and endpoints must be valid vertex indices. Duplicate arcs are idempotent, matching the source adjacency matrix.
- Each discovered cycle is encoded as its vertex sequence, the starting vertex again to close the cycle, then byte `255` as a record separator. Vertex IDs range from 0 through 5, so the separator is unambiguous. The function returns the encoded byte count; no cycles returns 0, malformed input returns `-1`, and insufficient output capacity returns `-2` without writing a partial result.
- The complete directed graph on six vertices attains the 2,786-byte output bound. All ports use fixed-size arrays and portable scalar operations.

The workload covers self-loops, reciprocal arcs, multiple and disconnected cycles, a DAG, duplicate arcs, malformed inputs, insufficient output capacity, and the maximum complete graph. The verifier corpus exhausts all directed graphs through three vertices and adds seeded larger graphs.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm directed_simple_cycles --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm directed_simple_cycles
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm directed_simple_cycles
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/d/directed_simple_cycles.c`](../../../c/d/directed_simple_cycles.c) |
| C3 | [`c3/d/directed_simple_cycles.c3`](../../../c3/d/directed_simple_cycles.c3) |
| C++ | [`cpp/d/directed_simple_cycles.cpp`](../../../cpp/d/directed_simple_cycles.cpp) |
| Elisa | [`elisa/d/directed_simple_cycles.elisa`](../../../elisa/d/directed_simple_cycles.elisa) |
| Nim | [`nim/d/directed_simple_cycles.nim`](../../../nim/d/directed_simple_cycles.nim) |
| Odin | [`odin/d/directed_simple_cycles.odin`](../../../odin/d/directed_simple_cycles.odin) |
| Rust | [`rust/d/directed_simple_cycles.rs`](../../../rust/d/directed_simple_cycles.rs) |
| V | [`v/d/directed_simple_cycles.v`](../../../v/d/directed_simple_cycles.v) |
| Zig | [`zig/d/directed_simple_cycles.zig`](../../../zig/d/directed_simple_cycles.zig) |
