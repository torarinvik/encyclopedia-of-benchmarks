# All paths from source to target

## Contract

Enumerate vertex-simple paths in a directed graph from a selected source to destination. The benchmark follows the pinned Java DFS: neighbors are visited in edge insertion order, and each path is emitted as soon as DFS reaches the destination. Parallel edges are retained and produce duplicate path records. A vertex cannot repeat within one path. If source equals destination, the result contains the one-vertex path.

The signed 64-bit input is `[vertex_count, edge_count, source, destination, (from,to)*]`. There are 1..8 vertices, 0..24 directed edges, and each endpoint is in `0..vertex_count-1`. Input edge order defines each adjacency list's traversal order. Self-edges and parallel edges are allowed. The DFS emits at most 1,000 paths; an input that would exceed that cap returns `-2`. Malformed input returns `-1`.

The byte output is a sequence of little-endian signed 64-bit values: `[path_count, (path_length, vertex_ids...)*]`. Each path record stores its length followed by the ordered vertex IDs. Duplicate paths remain separate records. The return value is the output byte count. Insufficient output capacity and the 1,000-path cap return `-2`.

This enumerates actual path sequences, unlike [`number_of_paths`](../../n/number_of_paths/README.md), which returns only a count and uses an adjacency matrix. The Java source stores results in a static list and does not clear it between calls; this benchmark treats each ABI call as a fresh invocation with an empty result list so the same input has a stable output.

## Workload and implementations

[`workload.json`](workload.json) covers DFS neighbor ordering, duplicate paths from parallel edges, cycle avoidance, source equal to destination, no-path output, and malformed vertices.

| Language | Source |
| --- | --- |
| C | [`c/a/all_paths_from_source_to_target.c`](../../../c/a/all_paths_from_source_to_target.c) |
| C3 | [`c3/a/all_paths_from_source_to_target.c3`](../../../c3/a/all_paths_from_source_to_target.c3) |
| C++ | [`cpp/a/all_paths_from_source_to_target.cpp`](../../../cpp/a/all_paths_from_source_to_target.cpp) |
| Elisa | [`elisa/a/all_paths_from_source_to_target.elisa`](../../../elisa/a/all_paths_from_source_to_target.elisa) |
| Nim | [`nim/a/all_paths_from_source_to_target.nim`](../../../nim/a/all_paths_from_source_to_target.nim) |
| Odin | [`odin/a/all_paths_from_source_to_target.odin`](../../../odin/a/all_paths_from_source_to_target.odin) |
| Rust | [`rust/a/all_paths_from_source_to_target.rs`](../../../rust/a/all_paths_from_source_to_target.rs) |
| V | [`v/a/all_paths_from_source_to_target.v`](../../../v/a/all_paths_from_source_to_target.v) |
| Zig | [`zig/a/all_paths_from_source_to_target.zig`](../../../zig/a/all_paths_from_source_to_target.zig) |

## Pinned source

- [Java `AllPathsFromSourceToTarget.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/backtracking/AllPathsFromSourceToTarget.java)
