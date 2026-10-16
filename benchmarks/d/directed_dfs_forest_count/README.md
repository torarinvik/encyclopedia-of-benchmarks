# Directed DFS forest count

Count the roots selected by the pinned Java `Graph.countGraphs()` traversal. The source calls these results connected components, but it follows directed edges only and does not compute weakly connected components or strongly connected components.

## Contract

- The `i64_array_scalar` input is `[edge_count, from_0, to_0, ...]`. There are 0 through 64 directed edges, and each endpoint is an integer label from 0 through 63. Vertices are introduced only by edges; the source has no operation for standalone isolated vertices.
- Process edges in input order. A newly encountered `from` vertex is added before a newly encountered `to` vertex. The forest scans node identities in insertion order. For each unmarked identity, it recursively follows outgoing edges and marks all reachable identities; the result is the number of roots that start a traversal.
- Duplicate directed edges are allowed. The source's `addEdge` uses `if (start matches) ... else if (end matches) ...`; for a self-loop this creates a second node identity with the same label and an edge from the previous latest identity to the new one. Later edges resolve to the latest identity for each label. The ports preserve this behavior because it can affect which roots remain unmarked.
- A valid packed input has at most 129 i64 values. Malformed lengths, edge counts, or labels return `-1`. Empty edge lists are valid and return 0.

The pinned [Java `ConnectedComponent.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/graphs/ConnectedComponent.java) builds its node list while adding directed edges. `countGraphs()` iterates that list, marks nodes reached by recursive outgoing-edge DFS, and increments once for each node that was not marked before its traversal. The root count can depend on edge insertion order; the workload includes both Java demo graphs, including its self-loop.

[`workload.json`](workload.json) covers the pinned demos, edge-order sensitivity, multiple incoming paths, duplicate edges, self-loop node identity, the maximum edge count, and malformed packed inputs. The independent oracle is [`directed_dfs_forest_count_oracle.py`](../../directed_dfs_forest_count_oracle.py).

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm directed_dfs_forest_count --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/d/directed_dfs_forest_count/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithms directed_dfs_forest_count
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/d/directed_dfs_forest_count.c`](../../../c/d/directed_dfs_forest_count.c) |
| C3 | [`c3/d/directed_dfs_forest_count.c3`](../../../c3/d/directed_dfs_forest_count.c3) |
| C++ | [`cpp/d/directed_dfs_forest_count.cpp`](../../../cpp/d/directed_dfs_forest_count.cpp) |
| Elisa | [`elisa/d/directed_dfs_forest_count.elisa`](../../../elisa/d/directed_dfs_forest_count.elisa) |
| Nim | [`nim/d/directed_dfs_forest_count.nim`](../../../nim/d/directed_dfs_forest_count.nim) |
| Odin | [`odin/d/directed_dfs_forest_count.odin`](../../../odin/d/directed_dfs_forest_count.odin) |
| Rust | [`rust/d/directed_dfs_forest_count.rs`](../../../rust/d/directed_dfs_forest_count.rs) |
| V | [`v/d/directed_dfs_forest_count.v`](../../../v/d/directed_dfs_forest_count.v) |
| Zig | [`zig/d/directed_dfs_forest_count.zig`](../../../zig/d/directed_dfs_forest_count.zig) |
