# Heavy-Light Decomposition Metadata

This benchmark reproduces the metadata produced by the pinned Rust HeavyLightDecomposition. The input is an insertion-ordered undirected tree rooted at vertex 0. The implementation first computes subtree sizes and the heavy child, then assigns decomposition positions in heavy-first depth-first order.

## Contract

Input is a signed 64-bit array [vertex_count, edge_count, (u, v)...]. There must be 1 through 128 vertices and exactly vertex_count-1 simple edges. Vertex labels are dense and zero-based. The graph must be connected; all vertices are present and the decomposition root is vertex 0. Each edge is undirected and is added in input order to both endpoint adjacency lists.

For every vertex, the Rust source chooses the first child in adjacency order with the largest subtree. Its comparison is strictly greater-than, so equal-sized later children do not replace the first. Decomposition visits the heavy child first, then light children in adjacency order.

Output is [vertex_count, (position, chain_head, heavy_child)*] in ascending vertex-label order, encoded as little-endian signed 64-bit values. Positions are zero-based. Chain heads are zero-based vertex labels. A heavy-child value is its zero-based label, or -1 for a leaf. The wrapper translates the source's one-based positions and node IDs into this zero-based contract. The function returns the number of output bytes. Invalid input returns -1; insufficient or null output capacity returns -2 without writing.

The maximum output is 385 signed 64-bit values (3,080 bytes). A single-vertex tree is valid and returns [1, 0, 0, -1].

## Build

Run:

python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm heavy_light_decomposition_metadata --language rust

python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/h/heavy_light_decomposition_metadata/rust/build.json

## Implementations

| Language | Source |
| --- | --- |
| C | [c/h/heavy_light_decomposition_metadata.c](../../../c/h/heavy_light_decomposition_metadata.c) |
| C3 | [c3/h/heavy_light_decomposition_metadata.c3](../../../c3/h/heavy_light_decomposition_metadata.c3) |
| C++ | [cpp/h/heavy_light_decomposition_metadata.cpp](../../../cpp/h/heavy_light_decomposition_metadata.cpp) |
| Elisa | [elisa/h/heavy_light_decomposition_metadata.elisa](../../../elisa/h/heavy_light_decomposition_metadata.elisa) |
| Nim | [nim/h/heavy_light_decomposition_metadata.nim](../../../nim/h/heavy_light_decomposition_metadata.nim) |
| Odin | [odin/h/heavy_light_decomposition_metadata.odin](../../../odin/h/heavy_light_decomposition_metadata.odin) |
| Rust | [rust/h/heavy_light_decomposition_metadata.rs](../../../rust/h/heavy_light_decomposition_metadata.rs) |
| V | [v/h/heavy_light_decomposition_metadata.v](../../../v/h/heavy_light_decomposition_metadata.v) |
| Zig | [zig/h/heavy_light_decomposition_metadata.zig](../../../zig/h/heavy_light_decomposition_metadata.zig) |

## Pinned source

- Rust [heavy_light_decomposition.rs](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/graph/heavy_light_decomposition.rs)
