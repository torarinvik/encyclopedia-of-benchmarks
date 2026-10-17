# Kruskal minimum spanning forest

This benchmark follows the pinned Python implementation of Kruskal's algorithm. It returns the accepted original edge triples in the order they are scanned after a stable weight-only sort. It processes every edge, so disconnected inputs return a minimum spanning forest.

## Contract

- The ABI uses the i64-array-bytes-output family. Input is the packed signed-i64 sequence [vertex_count, edge_count, u_0, v_0, weight_0, ...].
- Vertex count is 0 through 64, edge count is 0 through 4,096, and the packed length is exactly 2 + 3 * edge_count. Every endpoint must be in [0, vertex_count). Weights use the full signed-i64 range.
- Edges are considered as supplied. Self-loops are ignored by the component check. Parallel and reversed edges are separate candidates. Sorting compares weight only and preserves original input order for ties. Accepted output records preserve each input edge's endpoint orientation and weight.
- The algorithm uses path-compressed disjoint sets, appends an edge when its endpoints are in different components, and scans every edge. It returns the minimum spanning forest even when the graph is disconnected. The source's accumulated cost is unused and is not part of the benchmark.
- Output is the flat sequence of accepted (u, v, weight) triples, each encoded as little-endian signed i64. There is no count header; the result is the byte count, which is a multiple of 24. Empty forests return 0 bytes.
- Invalid input returns -1 before output-buffer checks. A null output pointer returns -2 even for an empty forest. A non-null buffer with insufficient capacity returns -2 without writing partial output; a non-null buffer with capacity 0 succeeds when the forest is empty.
- At most max(0, vertex_count - 1) edges can be accepted, so the maximum output is 1,512 bytes.

The existing kruskal benchmark returns only a scalar total for connected graphs. This package is separate because the pinned Python function returns the ordered forest edge list, including on disconnected graphs.

## Workload and oracle

The workload covers the pinned examples, disconnected forests, self-loops, parallel and reversed edges, negative and tied weights, signed-i64 weight boundaries, malformed input, and output capacity behavior. The independent component-label oracle is benchmarks/minimum_spanning_tree_kruskal_oracle.py.

Pinned source: [TheAlgorithms/Python minimum_spanning_tree_kruskal.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/minimum_spanning_tree_kruskal.py)

## Reproduce

~~~sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm minimum_spanning_tree_kruskal --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm minimum_spanning_tree_kruskal
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm minimum_spanning_tree_kruskal --languages rust
~~~

## Language ports

| Language | Source |
| --- | --- |
| C | [c/m/minimum_spanning_tree_kruskal.c](../../c/m/minimum_spanning_tree_kruskal.c) |
| C3 | [c3/m/minimum_spanning_tree_kruskal.c3](../../c3/m/minimum_spanning_tree_kruskal.c3) |
| C++ | [cpp/m/minimum_spanning_tree_kruskal.cpp](../../cpp/m/minimum_spanning_tree_kruskal.cpp) |
| Elisa | [elisa/m/minimum_spanning_tree_kruskal.elisa](../../elisa/m/minimum_spanning_tree_kruskal.elisa) |
| Nim | [nim/m/minimum_spanning_tree_kruskal.nim](../../nim/m/minimum_spanning_tree_kruskal.nim) |
| Odin | [odin/m/minimum_spanning_tree_kruskal.odin](../../odin/m/minimum_spanning_tree_kruskal.odin) |
| Rust | [rust/m/minimum_spanning_tree_kruskal.rs](../../rust/m/minimum_spanning_tree_kruskal.rs) |
| V | [v/m/minimum_spanning_tree_kruskal.v](../../v/m/minimum_spanning_tree_kruskal.v) |
| Zig | [zig/m/minimum_spanning_tree_kruskal.zig](../../zig/m/minimum_spanning_tree_kruskal.zig) |
