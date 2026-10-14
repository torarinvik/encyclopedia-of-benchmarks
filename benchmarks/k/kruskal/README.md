# Kruskal minimum spanning tree

Kruskal’s algorithm sorts undirected weighted edges from lightest to heaviest and joins components when an edge does not form a cycle. This benchmark returns the minimum spanning tree’s total weight. The pinned C and C++ sources both use edge sorting and disjoint sets, though the C source’s qsort comparator returns a boolean rather than a three-way ordering result. The shared contract makes edge ordering deterministic and normalizes graph handling across all nine ports.

## Contract

The packed signed 64-bit input is `[vertex_count, edge_count, u_0, v_0, weight_0, ...]`. Vertex IDs are zero-based. There may be 0–64 vertices and up to 4,096 edge records. Weights are in `[0, 2^31-1]`. Edges are undirected; self-loops are ignored and parallel edges are permitted. The function returns total minimum spanning tree weight, `0` for an empty graph or single vertex, `-1` when disconnected, and `-2` for malformed input.

Each port encodes an edge’s `(weight, lower endpoint, higher endpoint)` into an integer key, applies in-place heapsort, then performs union by rank with path compression. All encoded keys fit signed 64-bit. This keeps edge ordering and tie handling portable across compilers. Complexity is O(E log E + E α(V)) time and O(E + V) storage.

## Reproduce

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm kruskal --language c
python3 benchmarks/run_i64_array_scalar.py --algorithm kruskal
python3 benchmarks/verify_kruskal.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1
```

The verifier uses an independent dense Prim oracle over exhaustive small graphs, randomized graphs, boundary cases, and the published workload.

Upstream references: [C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/graphs/kruskal.c), [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/graph/kruskal.cpp), [Go](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/graph/kruskal.go), and [Swift](https://github.com/TheAlgorithms/Swift/blob/2c9eb8b85dee6db46cb33452c0b904eb7d7d179c/graph/spanning_tree/kruskal.swift).
