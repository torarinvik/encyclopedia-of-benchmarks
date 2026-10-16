# Welsh–Powell greedy coloring

This package ports the pinned Java `WelshPowell.findColoring` procedure. It sorts vertices by descending degree with stable ascending-index ties, then assigns colors greedily. For each new color it scans the sorted order and also colors each still-uncolored vertex that has no already-colored neighbor of any color. That last rule follows the source exactly. The algorithm is a greedy heuristic and does not guarantee a minimum-coloring.

## Contract

- Input is `[vertex_count, edge_count, u0, v0, ...]`, with undirected edge endpoint pairs. Vertex count is `0..32`, and edge-pair count is `0..512`. The input length must be exactly `2 + 2 * edge_count`.
- Vertices are numbered `0..vertex_count-1`. Self-loops and out-of-range endpoints are invalid. Repeated edges collapse, matching the source graph's `HashSet` adjacency lists.
- The result is one zero-based color ID per vertex, in original vertex order, encoded as little-endian signed 64-bit words. An empty graph returns a zero-length output. Invalid input returns `-1`; a null output pointer or insufficient capacity returns `-2`.
- The empty graph is valid and produces an empty coloring.

The independent oracle is [`benchmarks/welsh_powell_oracle.py`](../../welsh_powell_oracle.py). The workload covers empty and isolated graphs, degree ordering, stable ties, duplicate edges, source greedy behavior, self-loops, malformed inputs, and output-capacity boundaries.

Pinned source: [TheAlgorithms/Java `WelshPowell.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/graphs/WelshPowell.java), commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.

Build and record with the `i64_array_bytes_output` ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm welsh_powell --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm welsh_powell
```

| Language | Port |
| --- | --- |
| C | [`c/w/welsh_powell.c`](../../../c/w/welsh_powell.c) |
| C3 | [`c3/w/welsh_powell.c3`](../../../c3/w/welsh_powell.c3) |
| C++ | [`cpp/w/welsh_powell.cpp`](../../../cpp/w/welsh_powell.cpp) |
| Elisa | [`elisa/w/welsh_powell.elisa`](../../../elisa/w/welsh_powell.elisa) |
| Nim | [`nim/w/welsh_powell.nim`](../../../nim/w/welsh_powell.nim) |
| Odin | [`odin/w/welsh_powell.odin`](../../../odin/w/welsh_powell.odin) |
| Rust | [`rust/w/welsh_powell.rs`](../../../rust/w/welsh_powell.rs) |
| V | [`v/w/welsh_powell.v`](../../../v/w/welsh_powell.v) |
| Zig | [`zig/w/welsh_powell.zig`](../../../zig/w/welsh_powell.zig) |
