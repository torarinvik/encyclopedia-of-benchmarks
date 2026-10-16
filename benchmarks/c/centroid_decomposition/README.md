# Centroid Decomposition

This benchmark builds the centroid tree of an undirected tree. It repeatedly finds a vertex whose removal leaves no component larger than half of the current component, records that vertex's parent in the centroid tree, removes it, and processes the remaining components.

## Contract

- Input is `[node_count, edge_u_0, edge_v_0, ...]`, with zero-based vertex IDs and `node_count` from 1 through 64.
- There must be exactly `node_count - 1` edges. Endpoints must be in range, self-edges and cycles are invalid, and the resulting graph must be a tree.
- Return `node_count` and write one signed 32-bit parent ID per original vertex in little-endian order. The centroid-tree root has parent `-1`.
- If multiple vertices are equally balanced centroids, choose the one with the lowest vertex ID. This makes results stable across edge order and language.
- Invalid input returns `-1`. Insufficient output capacity returns `-2` without writing.
- The bounded implementations use iterative component walks and subtree sizes. Time is O(n log n) after the adjacency list is built; auxiliary space is O(n).

The pinned Rust source uses vertices numbered from 1 and reports parent 0 for its root. The pinned Java source uses vertices numbered from 0 and parent -1 for its root. This benchmark normalizes both to zero-based vertices and the Java root sentinel. Their centroid choices can differ on ties, so the contract resolves ties by lowest vertex ID.

## Workload and verification

`workload.json` covers singleton and two-vertex trees, paths, stars, a balanced tree, a branching tree, the maximum input size, malformed graphs, and output-capacity failures. The verifier also enumerates every labeled tree through five vertices and checks seeded random trees against a separate oracle that measures each candidate centroid's branches directly.

Run all nine implementations with:

```sh
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm centroid_decomposition --elisa-compiler ../Elisa-compiler/bin/elisac-stage1
```

## Pinned sources

- [TheAlgorithms/Rust `centroid_decomposition.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/graph/centroid_decomposition.rs)
- [TheAlgorithms/Java `CentroidDecomposition.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/CentroidDecomposition.java)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/c/centroid_decomposition.c](../../../c/c/centroid_decomposition.c) |
| C3 | [c3/c/centroid_decomposition.c3](../../../c3/c/centroid_decomposition.c3) |
| C++ | [cpp/c/centroid_decomposition.cpp](../../../cpp/c/centroid_decomposition.cpp) |
| Elisa | [elisa/c/centroid_decomposition.elisa](../../../elisa/c/centroid_decomposition.elisa) |
| Nim | [nim/c/centroid_decomposition.nim](../../../nim/c/centroid_decomposition.nim) |
| Odin | [odin/c/centroid_decomposition.odin](../../../odin/c/centroid_decomposition.odin) |
| Rust | [rust/c/centroid_decomposition.rs](../../../rust/c/centroid_decomposition.rs) |
| V | [v/c/centroid_decomposition.v](../../../v/c/centroid_decomposition.v) |
| Zig | [zig/c/centroid_decomposition.zig](../../../zig/c/centroid_decomposition.zig) |
