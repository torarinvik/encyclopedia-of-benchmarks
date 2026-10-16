# Rust Weighted Undirected Graph

This benchmark preserves the neighbor-list behavior of the pinned Rust UndirectedGraph. It creates a graph with dense string labels from 0 through n-1, inserts weighted edges in input order, then queries every node's neighbors in label order. Each neighbor list retains edge insertion order, parallel edges, and the source's two entries for a self-loop.

## Contract

Input is a signed 64-bit array [vertex_count, edge_count, (u, v, weight)...]. The vertex count is 0 through 64, and the edge count is 0 through 256. Endpoints are dense labels in [0, vertex_count), and each weight fits a signed 32-bit integer. All vertices are added before edges. Self-loops and repeated edges are valid and retain their insertion behavior.

Output is a little-endian signed 64-bit vector beginning with vertex_count. For each node in ascending label order, it contains [neighbor_count, neighbor_0, weight_0, ...]. Neighbors appear in input edge order; an undirected edge adds one entry to each endpoint, while a self-loop adds two entries to that node. The function returns the number of output bytes written. Invalid input returns -1; insufficient or null output capacity returns -2 without writing.

The maximum output is 1,089 signed 64-bit values (8,712 bytes). The empty graph serializes as [0].

## Build

Run:

python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm graph_rust_weighted --language rust

python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/g/graph_rust_weighted/rust/build.json

## Implementations

| Language | Source |
| --- | --- |
| C | [c/g/graph_rust_weighted.c](../../../c/g/graph_rust_weighted.c) |
| C3 | [c3/g/graph_rust_weighted.c3](../../../c3/g/graph_rust_weighted.c3) |
| C++ | [cpp/g/graph_rust_weighted.cpp](../../../cpp/g/graph_rust_weighted.cpp) |
| Elisa | [elisa/g/graph_rust_weighted.elisa](../../../elisa/g/graph_rust_weighted.elisa) |
| Nim | [nim/g/graph_rust_weighted.nim](../../../nim/g/graph_rust_weighted.nim) |
| Odin | [odin/g/graph_rust_weighted.odin](../../../odin/g/graph_rust_weighted.odin) |
| Rust | [rust/g/graph_rust_weighted.rs](../../../rust/g/graph_rust_weighted.rs) |
| V | [v/g/graph_rust_weighted.v](../../../v/g/graph_rust_weighted.v) |
| Zig | [zig/g/graph_rust_weighted.zig](../../../zig/g/graph_rust_weighted.zig) |

## Pinned source

- Rust [graph.rs](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/data_structures/graph.rs)
