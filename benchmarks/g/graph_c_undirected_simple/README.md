# C undirected simple graph

This package ports the C graph ADT's undirected adjacency-matrix behavior. Vertices are labeled from zero. Inserting an edge sets both symmetric matrix cells; repeated insertions have no additional effect. A self-loop sets the corresponding diagonal cell.

## Contract

Input is a signed 64-bit vector `[vertex_count, edge_count, (left, right)...]`. The vertex count is 1 through 32, and there are 0 through 2,047 edge records. Both endpoints must be in `[0, vertex_count)`. Edges are undirected. Duplicate edges and self-loops are accepted and idempotent. The input length must equal `2 + 2 * edge_count`.

Output is the `vertex_count × vertex_count` adjacency matrix, row-major, with each 0/1 cell encoded as a little-endian signed 64-bit integer. The return value is the number of output bytes (`vertex_count * vertex_count * 8`). Malformed input returns `-1`; null or insufficient output capacity returns `-2` without writing. The edge-record limit keeps the packed input within the shared 4,096-value array-output ABI limit.

The workload covers an empty graph, a path, symmetry, repeated/reversed edges, self-loops, the maximum matrix size, the maximum packed edge-record count, invalid inputs, and insufficient output capacity.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm graph_c_undirected_simple --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/g/graph_c_undirected_simple/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/g/graph_c_undirected_simple.c`](../../../c/g/graph_c_undirected_simple.c) |
| C3 | [`c3/g/graph_c_undirected_simple.c3`](../../../c3/g/graph_c_undirected_simple.c3) |
| C++ | [`cpp/g/graph_c_undirected_simple.cpp`](../../../cpp/g/graph_c_undirected_simple.cpp) |
| Elisa | [`elisa/g/graph_c_undirected_simple.elisa`](../../../elisa/g/graph_c_undirected_simple.elisa) |
| Nim | [`nim/g/graph_c_undirected_simple.nim`](../../../nim/g/graph_c_undirected_simple.nim) |
| Odin | [`odin/g/graph_c_undirected_simple.odin`](../../../odin/g/graph_c_undirected_simple.odin) |
| Rust | [`rust/g/graph_c_undirected_simple.rs`](../../../rust/g/graph_c_undirected_simple.rs) |
| V | [`v/g/graph_c_undirected_simple.v`](../../../v/g/graph_c_undirected_simple.v) |
| Zig | [`zig/g/graph_c_undirected_simple.zig`](../../../zig/g/graph_c_undirected_simple.zig) |

## Pinned source references

- [C `graph.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/graphs/graph.c)
- [C `graph.h`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/graphs/graph.h)
