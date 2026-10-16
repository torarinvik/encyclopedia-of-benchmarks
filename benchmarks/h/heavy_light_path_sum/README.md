# Heavy-light path sum

This package implements point updates and inclusive node-path sum queries on a rooted tree, using heavy-light decomposition with a segment tree. The root is vertex 0. Both pinned C++ sources describe the same operation: set one node's value, or sum all node values on the simple path between two vertices.

## Contract

Input is a signed 64-bit array `[vertex_count, operation_count, node_values..., (edge_u, edge_v)..., (operation, a, b_or_value)...]`. There are 1 through 64 vertices and 0 through 128 operations. The graph must be a connected simple undirected tree with exactly `vertex_count - 1` edges. Vertex labels are dense and zero-based. Initial and updated values must fit signed 32-bit integers.

Operation `0` sets node `a` to value `b`. Operation `1` queries the inclusive node-value sum along the path from `a` to `b`. Output contains one signed 64-bit sum per query, in query order, encoded little-endian. Success returns the number of output bytes. Malformed input returns `-1`; insufficient output capacity returns `-2` without writing.

The bounds keep every path sum within signed 64-bit. The workload covers a singleton, a chain, a star, branching paths, negative values, repeated updates, the maximum tree size and operation count, malformed trees and operations, and output capacity errors.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm heavy_light_path_sum --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/h/heavy_light_path_sum/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/h/heavy_light_path_sum.c`](../../../c/h/heavy_light_path_sum.c) |
| C3 | [`c3/h/heavy_light_path_sum.c3`](../../../c3/h/heavy_light_path_sum.c3) |
| C++ | [`cpp/h/heavy_light_path_sum.cpp`](../../../cpp/h/heavy_light_path_sum.cpp) |
| Elisa | [`elisa/h/heavy_light_path_sum.elisa`](../../../elisa/h/heavy_light_path_sum.elisa) |
| Nim | [`nim/h/heavy_light_path_sum.nim`](../../../nim/h/heavy_light_path_sum.nim) |
| Odin | [`odin/h/heavy_light_path_sum.odin`](../../../odin/h/heavy_light_path_sum.odin) |
| Rust | [`rust/h/heavy_light_path_sum.rs`](../../../rust/h/heavy_light_path_sum.rs) |
| V | [`v/h/heavy_light_path_sum.v`](../../../v/h/heavy_light_path_sum.v) |
| Zig | [`zig/h/heavy_light_path_sum.zig`](../../../zig/h/heavy_light_path_sum.zig) |

## Pinned sources

- [TheAlgorithms/C-Plus-Plus `heavy_light_decomposition.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/range_queries/heavy_light_decomposition.cpp)
- [TheAlgorithms/C-Plus-Plus-1 mirror `heavy_light_decomposition.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/range_queries/heavy_light_decomposition.cpp)
