# Hierholzer Eulerian circuit

Find an Eulerian circuit in the pinned Java implementation’s undirected multigraph, preserving its traversal order.

## Contract

The `i64_array_scalar` input is `[vertex_count, edge_count, (u, v)...]`, with `vertex_count` in 0..8, `edge_count` in 0..256, and exact length `2 + 2*edge_count`. Each endpoint is in `0..vertex_count-1`. Initialize keys for every vertex in ascending order, then append both adjacency entries for each edge in input order; a self-loop contributes two entries to the same list. The result is a low-63-bit standard FNV-1a-64 hash over signed-i64 little-endian words `[has_circuit, route_length, route_vertices...]`.

The implementation returns an empty route for a disconnected nonzero-degree graph or odd degree. An empty graph has `has_circuit = 1` and an empty route. A nonempty edgeless graph returns `[0]`. For a nonempty Eulerian graph, start at the first nonempty vertex in ascending order, repeatedly consume the first adjacency and remove the first matching reverse entry, then prepend vertices as the stack unwinds. This preserves the source’s `pollFirst`/`addFirst` traversal order. Malformed inputs return `-1`.

## Source

- Java [`HierholzerAlgorithm.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/graph/HierholzerAlgorithm.java)

## Workload and verification

[`workload.json`](workload.json) covers empty and edgeless graphs, self-loops, parallel edges, connected and disconnected components, odd degrees, input-order effects, invalid records, and the 256-edge boundary. The independent oracle hashes the route record with FNV-1a-64.

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm hierholzer_algorithm --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/h/hierholzer_algorithm/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/h/hierholzer_algorithm.c`](../../../c/h/hierholzer_algorithm.c) |
| C3 | [`c3/h/hierholzer_algorithm.c3`](../../../c3/h/hierholzer_algorithm.c3) |
| C++ | [`cpp/h/hierholzer_algorithm.cpp`](../../../cpp/h/hierholzer_algorithm.cpp) |
| Elisa | [`elisa/h/hierholzer_algorithm.elisa`](../../../elisa/h/hierholzer_algorithm.elisa) |
| Nim | [`nim/h/hierholzer_algorithm.nim`](../../../nim/h/hierholzer_algorithm.nim) |
| Odin | [`odin/h/hierholzer_algorithm.odin`](../../../odin/h/hierholzer_algorithm.odin) |
| Rust | [`rust/h/hierholzer_algorithm.rs`](../../../rust/h/hierholzer_algorithm.rs) |
| V | [`v/h/hierholzer_algorithm.v`](../../../v/h/hierholzer_algorithm.v) |
| Zig | [`zig/h/hierholzer_algorithm.zig`](../../../zig/h/hierholzer_algorithm.zig) |
