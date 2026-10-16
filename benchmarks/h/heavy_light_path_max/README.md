# Heavy-light path maximum

This benchmark ports the pinned Java heavy-light decomposition's point updates and inclusive node-path maximum queries. The tree is rooted at vertex `0`; external vertex labels are dense and zero-based. The Java source uses one-based internal arrays, which is an implementation detail of that port.

## Contract

Input is a signed 64-bit array:

```text
[vertex_count, operation_count, node_values..., (edge_u, edge_v)..., (operation, a, b_or_value)...]
```

There are 1 through 64 vertices and 0 through 128 operations. The graph must be a connected simple undirected tree with exactly `vertex_count - 1` edges. Initial and updated node values are signed 32-bit integers.

Operation `0` sets node `a` to value `b`. Operation `1` returns the maximum node value on the inclusive path from `a` to `b`. Output contains one signed 64-bit maximum per query, in query order, encoded little-endian. Success returns the number of bytes written. Malformed input returns `-1`; insufficient output capacity returns `-2` without writing. The maximum output size is 1,024 bytes.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm heavy_light_path_max --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/h/heavy_light_path_max/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/h/heavy_light_path_max.c`](../../../c/h/heavy_light_path_max.c) |
| C3 | [`c3/h/heavy_light_path_max.c3`](../../../c3/h/heavy_light_path_max.c3) |
| C++ | [`cpp/h/heavy_light_path_max.cpp`](../../../cpp/h/heavy_light_path_max.cpp) |
| Elisa | [`elisa/h/heavy_light_path_max.elisa`](../../../elisa/h/heavy_light_path_max.elisa) |
| Nim | [`nim/h/heavy_light_path_max.nim`](../../../nim/h/heavy_light_path_max.nim) |
| Odin | [`odin/h/heavy_light_path_max.odin`](../../../odin/h/heavy_light_path_max.odin) |
| Rust | [`rust/h/heavy_light_path_max.rs`](../../../rust/h/heavy_light_path_max.rs) |
| V | [`v/h/heavy_light_path_max.v`](../../../v/h/heavy_light_path_max.v) |
| Zig | [`zig/h/heavy_light_path_max.zig`](../../../zig/h/heavy_light_path_max.zig) |

## Pinned source

- [TheAlgorithms/Java `HeavyLightDecomposition.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/HeavyLightDecomposition.java)
