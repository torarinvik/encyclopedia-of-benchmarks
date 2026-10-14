# Prim minimum spanning tree

Prim’s algorithm grows a minimum spanning tree from vertex 0 by repeatedly adding the cheapest edge that reaches a vertex outside the tree. This benchmark returns the total tree weight. The pinned C implementation uses an adjacency matrix, while the C++, Python, and Rust sources use adjacency-list or heap-based forms. The shared contract normalizes the input and output so each implementation solves the same connected-graph problem.

## Contract

The input is a packed signed 64-bit array: `[vertex_count, edge_count, u_0, v_0, weight_0, ...]`. Vertex IDs are zero-based. There may be 0–64 vertices and up to 4,096 edge records. Edge weights are in `[0, 2^31-1]`. The graph is undirected; self-loops are ignored and repeated edges between a pair are coalesced to their minimum weight. The result is the minimum spanning tree’s total weight, `0` for the empty graph or a single vertex, `-1` for a disconnected graph, and `-2` for malformed input.

The implementations use a portable dense Prim scan over a fixed 64-vertex matrix. It takes O(V² + E) time and bounded O(V²) storage, so benchmark behavior does not depend on an architecture-specific instruction set or a library priority queue.

## Reproduce

Build and record with the i64 array-scalar ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm prim --language c
python3 benchmarks/run_i64_array_scalar.py --algorithm prim
python3 benchmarks/verify_prim.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1
```

The verifier compares all nine implementations with an independent Kruskal oracle over exhaustive small graphs, random graphs, boundary cases, and the workload. The pinned C source assumes a connected weighted graph and a 20-vertex limit; C++ and Rust return the spanning tree rooted at a selected vertex, with Rust documenting component behavior for disconnected input.

Upstream references: [C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/greedy_approach/prim.c), [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/graph/prim.cpp), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/prim.py), and [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/graph/prim.rs).
