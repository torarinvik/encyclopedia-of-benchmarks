# Directed Eulerian path

Find a directed walk that uses every edge exactly once. This is the canonical directed Hierholzer benchmark; it consolidates the equivalent Java `hierholzer_eulerian_path` profile under one workload and normalized output contract. It is separate from [`eulerian_trail_undirected_simple`](../eulerian_trail_undirected_simple/README.md), which operates on a simple undirected graph.

## Contract

- Input is `[vertex_count, edge_count, source_0, destination_0, ...]` in the signed 64-bit array ABI.
- There are 0–32 vertices and 0–256 directed edges. The packed input contains exactly two header values and two endpoints per edge. Parallel edges and self-loops are valid.
- A path exists when directed degree differences are zero everywhere, or exactly one vertex has out-degree one greater and one has in-degree one greater, and one traversal can consume every edge. Isolated declared vertices are allowed.
- The start is the unique vertex with `out_degree - in_degree == 1`; for a circuit, it is the lowest vertex with an outgoing edge, matching the pinned source.
- Output is the path's vertex sequence as little-endian signed 64-bit values. The return value is the output byte count. No path (including an empty-edge graph) returns 0 with empty output; malformed input returns -1; insufficient output capacity returns -2.
- The Rust source consumes each vertex's adjacency list from the end. The ports preserve input edge order and use an iterative Hierholzer stack with fixed storage, avoiding recursion-depth and platform-specific behavior.

[`workload.json`](workload.json) covers open paths, circuits, parallel edges, self-loops, disconnected components, invalid degrees and endpoints, empty graphs, maximum edge count, and output-capacity failure.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm eulerian_path --language c
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/e/eulerian_path/c/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithms eulerian_path
```

## Source

- [Rust `eulerian_path.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/graph/eulerian_path.rs)
- [Java `HierholzerEulerianPath.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/graph/HierholzerEulerianPath.java) (same directed Hierholzer algorithm; its vertex-count prefix and narrower bounds are normalized here)

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/e/eulerian_path.c`](../../../c/e/eulerian_path.c) |
| C3 | [`c3/e/eulerian_path.c3`](../../../c3/e/eulerian_path.c3) |
| C++ | [`cpp/e/eulerian_path.cpp`](../../../cpp/e/eulerian_path.cpp) |
| Elisa | [`elisa/e/eulerian_path.elisa`](../../../elisa/e/eulerian_path.elisa) |
| Nim | [`nim/e/eulerian_path.nim`](../../../nim/e/eulerian_path.nim) |
| Odin | [`odin/e/eulerian_path.odin`](../../../odin/e/eulerian_path.odin) |
| Rust | [`rust/e/eulerian_path.rs`](../../../rust/e/eulerian_path.rs) |
| V | [`v/e/eulerian_path.v`](../../../v/e/eulerian_path.v) |
| Zig | [`zig/e/eulerian_path.zig`](../../../zig/e/eulerian_path.zig) |
