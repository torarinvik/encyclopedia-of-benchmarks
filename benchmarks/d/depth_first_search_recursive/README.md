# Recursive depth-first reachability

Return whether a target vertex is reachable from a source vertex in an unweighted, undirected graph. This package preserves the recursive search used by the pinned JavaScript source; it is separate from [`depth_first_search_iterative`](../depth_first_search_iterative/README.md), which uses an explicit stack.

## Contract

- The `i64_array_scalar` input is `[vertex_count, edge_count, source, target, (left, right)...]`.
- The graph has 1–64 vertices labeled `0` through `vertex_count - 1` and 0–256 undirected edges. The source must be a present vertex. Target may be any signed 64-bit integer; a target outside the graph returns 0.
- Edges are added in input order. Duplicate edges and self-loops are allowed and have the same set behavior as the source. Every declared vertex exists, including isolated vertices.
- Return 1 if the target is reachable, 0 otherwise, and -1 for malformed packed input.
- The ports build insertion-ordered adjacency lists from the packed edges, suppress duplicate neighbors with per-vertex bit masks, then recurse through each neighbor while tracking visited vertices. Search time is O(V + E), with fixed local capacity for 64 vertices; maximum recursion depth is 64.

Pinned source: [TheAlgorithms/JavaScript `DepthFirstSearchRecursive.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Graphs/DepthFirstSearchRecursive.js).

[`workload.json`](workload.json) covers the pinned example, source-equals-target, isolated and disconnected vertices, reverse undirected traversal, duplicate edges, self-loops, cycles, signed target bounds, maximum graph size, and malformed inputs. The independent oracle uses breadth-first search.

Build and verify with the shared scalar-array tools:

    python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm depth_first_search_recursive --language rust --with-checker
    python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/d/depth_first_search_recursive/rust/build.json
    python3 benchmarks/verify_i64_array_scalar.py --algorithms depth_first_search_recursive --languages rust

| Language | Source |
| --- | --- |
| C | [`c/d/depth_first_search_recursive.c`](../../../c/d/depth_first_search_recursive.c) |
| C3 | [`c3/d/depth_first_search_recursive.c3`](../../../c3/d/depth_first_search_recursive.c3) |
| C++ | [`cpp/d/depth_first_search_recursive.cpp`](../../../cpp/d/depth_first_search_recursive.cpp) |
| Elisa | [`elisa/d/depth_first_search_recursive.elisa`](../../../elisa/d/depth_first_search_recursive.elisa) |
| Nim | [`nim/d/depth_first_search_recursive.nim`](../../../nim/d/depth_first_search_recursive.nim) |
| Odin | [`odin/d/depth_first_search_recursive.odin`](../../../odin/d/depth_first_search_recursive.odin) |
| Rust | [`rust/d/depth_first_search_recursive.rs`](../../../rust/d/depth_first_search_recursive.rs) |
| V | [`v/d/depth_first_search_recursive.v`](../../../v/d/depth_first_search_recursive.v) |
| Zig | [`zig/d/depth_first_search_recursive.zig`](../../../zig/d/depth_first_search_recursive.zig) |
