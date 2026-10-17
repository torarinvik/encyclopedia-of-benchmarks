# Prim minimum spanning tree

This benchmark ports the pinned Python `prisms_algorithm` implementation, including its indexed binary heap. The source's misspelled function name is preserved in the source metadata; the benchmark symbol is `minimum_spanning_tree_prims`.

## Contract

- The ABI is `i32_array_bytes_output`. Input is `[vertex_count, edge_count, (u, v, weight)...]` as signed-i32 words, with exactly `2 + 3*edge_count` elements. There are 1–16 vertices and 0–64 edges. Edges must use canonical endpoints `0 <= u < v < vertex_count`, appear only once, and have signed-i32 weights. Graphs with more than one vertex must be connected; a one-vertex graph has no edges.
- The source initializes heap keys with Python `sys.maxsize`; this contract pins that sentinel to the 64-bit value `9,223,372,036,854,775,807`. Every accepted signed-i32 edge weight is strictly below it.
- Adjacency lists are built in edge input order, appending each undirected edge to `u` and then `v`; vertex 0 is the root. The source heap starts with vertices in ascending order. During sift-down it chooses the right child when child keys tie and swaps only when the chosen key is strictly smaller. Decrease-key is also strict, so an equal-weight candidate does not replace the first parent recorded for a vertex.
- Output is `[vertex_count - 1, (parent, child)...]` in extraction order, serialized as little-endian signed-i32 values. Weights are omitted. The one-vertex graph returns `[0]`. The maximum output is 124 bytes. Malformed, disconnected, or null input returns `-1` before output-buffer checks; a null output or insufficient capacity returns `-2` without writes.

The fixtures cover equal-key heap behavior, first-parent retention, decrease-key updates, edge-order-sensitive adjacency, negative and boundary weights, connectivity, malformed records, maximum input/output, and buffer capacity. See [workload.json](workload.json) and the independent [oracle](../../minimum_spanning_tree_prims_oracle.py).

Pinned source: [TheAlgorithms/Python `minimum_spanning_tree_prims.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/minimum_spanning_tree_prims.py), function `prisms_algorithm`, at commit `e1a2a8b016001309a73d5fec4818c35cca139795`.

## Reproduce

~~~
python3 benchmarks/build_abi.py --family i32_array_bytes_output --algorithm minimum_spanning_tree_prims --language rust
python3 benchmarks/run_i32_array_bytes_output.py --build-manifest build/i32_array_bytes_output/m/minimum_spanning_tree_prims/rust/build.json
python3 benchmarks/verify_i32_array_bytes_output.py --algorithm minimum_spanning_tree_prims --languages rust
~~~

## Language ports

| Language | Source |
| --- | --- |
| C | [c/m/minimum_spanning_tree_prims.c](../../../c/m/minimum_spanning_tree_prims.c) |
| C3 | [c3/m/minimum_spanning_tree_prims.c3](../../../c3/m/minimum_spanning_tree_prims.c3) |
| C++ | [cpp/m/minimum_spanning_tree_prims.cpp](../../../cpp/m/minimum_spanning_tree_prims.cpp) |
| Elisa | [elisa/m/minimum_spanning_tree_prims.elisa](../../../elisa/m/minimum_spanning_tree_prims.elisa) |
| Nim | [nim/m/minimum_spanning_tree_prims.nim](../../../nim/m/minimum_spanning_tree_prims.nim) |
| Odin | [odin/m/minimum_spanning_tree_prims.odin](../../../odin/m/minimum_spanning_tree_prims.odin) |
| Rust | [rust/m/minimum_spanning_tree_prims.rs](../../../rust/m/minimum_spanning_tree_prims.rs) |
| V | [v/m/minimum_spanning_tree_prims.v](../../../v/m/minimum_spanning_tree_prims.v) |
| Zig | [zig/m/minimum_spanning_tree_prims.zig](../../../zig/m/minimum_spanning_tree_prims.zig) |
