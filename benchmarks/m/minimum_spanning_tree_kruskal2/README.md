# Kruskal minimum spanning tree (variant 2)

This benchmark ports the pinned Python `GraphUndirectedWeighted.kruskal` behavior for a bounded connected undirected graph. The result records the edges in the order Kruskal accepts them.

## Contract

- The ABI is `i32_array_bytes_output`. Input is `[vertex_count, edge_count, (u, v, weight)...]` as signed-i32 values, with 1–16 vertices, 0–64 edges, and exactly `2 + 3 * edge_count` words. Vertices are numbered `0..vertex_count-1`. Each edge must use canonical endpoints `0 <= u < v < vertex_count`, appear only once, and carry a signed-i32 weight.
- All vertices are added in ascending order before the edges are inserted in input order. The pinned source scans nodes in that order and each node's neighbors in insertion order, then performs a stable ascending sort by weight. Equal-weight edges therefore retain the source's node/neighbor scan order. The output preserves the accepted-edge order and keeps each edge as `(u, v, weight)`.
- Graphs with more than one vertex must be connected. A one-vertex graph has no edges and returns `[0]`. Disconnected or malformed input returns `-1` before output-buffer checks; this bounded contract rejects disconnected graphs rather than reproducing the source's out-of-range edge-list access.
- Output is `[edge_count, (u, v, weight)...]` serialized as little-endian signed-i32 values. A connected graph with `n` vertices emits `n-1` accepted edges; the maximum output is 184 bytes. A null output pointer or insufficient capacity returns `-2` without writes.

The fixtures in [workload.json](workload.json) cover stable tie order, cycle rejection, negative and boundary weights, connectivity and shape validation, maximum input/output, and output capacity behavior. The independent oracle is [minimum_spanning_tree_kruskal2_oracle.py](../../minimum_spanning_tree_kruskal2_oracle.py).

Pinned source: [TheAlgorithms/Python `minimum_spanning_tree_kruskal2.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/minimum_spanning_tree_kruskal2.py) at commit `e1a2a8b016001309a73d5fec4818c35cca139795`.

## Reproduce

~~~
python3 benchmarks/build_abi.py --family i32_array_bytes_output --algorithm minimum_spanning_tree_kruskal2 --language rust
python3 benchmarks/run_i32_array_bytes_output.py --build-manifest build/i32_array_bytes_output/m/minimum_spanning_tree_kruskal2/rust/build.json
python3 benchmarks/verify_i32_array_bytes_output.py --algorithm minimum_spanning_tree_kruskal2 --languages rust
~~~

## Language ports

| Language | Source |
| --- | --- |
| C | [c/m/minimum_spanning_tree_kruskal2.c](../../../c/m/minimum_spanning_tree_kruskal2.c) |
| C3 | [c3/m/minimum_spanning_tree_kruskal2.c3](../../../c3/m/minimum_spanning_tree_kruskal2.c3) |
| C++ | [cpp/m/minimum_spanning_tree_kruskal2.cpp](../../../cpp/m/minimum_spanning_tree_kruskal2.cpp) |
| Elisa | [elisa/m/minimum_spanning_tree_kruskal2.elisa](../../../elisa/m/minimum_spanning_tree_kruskal2.elisa) |
| Nim | [nim/m/minimum_spanning_tree_kruskal2.nim](../../../nim/m/minimum_spanning_tree_kruskal2.nim) |
| Odin | [odin/m/minimum_spanning_tree_kruskal2.odin](../../../odin/m/minimum_spanning_tree_kruskal2.odin) |
| Rust | [rust/m/minimum_spanning_tree_kruskal2.rs](../../../rust/m/minimum_spanning_tree_kruskal2.rs) |
| V | [v/m/minimum_spanning_tree_kruskal2.v](../../../v/m/minimum_spanning_tree_kruskal2.v) |
| Zig | [zig/m/minimum_spanning_tree_kruskal2.zig](../../../zig/m/minimum_spanning_tree_kruskal2.zig) |
