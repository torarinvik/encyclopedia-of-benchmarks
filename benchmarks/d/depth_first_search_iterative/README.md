# Iterative depth-first reachability

Return whether a target node is reachable from a start node in an unweighted, undirected graph.

## Contract

The `i64_array_scalar` input is `[vertex_count, edge_count, source, target, (left, right)...]`. It contains 1 through 64 vertices labeled `0` through `vertex_count - 1`, and 0 through 256 undirected edges. The source must be a present vertex. The target may be any signed 64-bit integer; a target absent from the graph returns false. This includes values outside JavaScript’s safe-integer range because no such value can match the bounded node IDs 0 through 63. Duplicate edges and self-loops are allowed. The input length must equal `4 + 2 * edge_count`, up to 516 integers. The workload also includes a 257-edge malformed case to check that the edge limit is enforced.

The result is `1` when the target is reachable and `0` otherwise. Malformed inputs return `-1`. All vertices are considered present before edges are added, which lets workloads express isolated vertices.

The pinned [TheAlgorithms/JavaScript `DepthFirstSearchIterative.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Graphs/DepthFirstSearchIterative.js) stores an undirected graph in neighbor sets and returns a Boolean from `DFSIterative(node, value)`. The benchmark keeps that reachability result while bounding vertex IDs and inputs. The ports mark vertices when they enter the stack, so duplicate edges cannot grow the pending stack; the result remains the source method's reachability Boolean.

[`workload.json`](workload.json) covers connected and disconnected graphs, reverse traversal over an undirected edge, cycles, duplicate edges, self-loops, isolated vertices, the graph bounds, and malformed inputs. The independent [breadth-first oracle](../../depth_first_search_iterative_oracle.py) checks reachability separately from the ports' stack search.

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm depth_first_search_iterative --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/d/depth_first_search_iterative/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithms depth_first_search_iterative
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/d/depth_first_search_iterative.c`](../../../c/d/depth_first_search_iterative.c) |
| C3 | [`c3/d/depth_first_search_iterative.c3`](../../../c3/d/depth_first_search_iterative.c3) |
| C++ | [`cpp/d/depth_first_search_iterative.cpp`](../../../cpp/d/depth_first_search_iterative.cpp) |
| Elisa | [`elisa/d/depth_first_search_iterative.elisa`](../../../elisa/d/depth_first_search_iterative.elisa) |
| Nim | [`nim/d/depth_first_search_iterative.nim`](../../../nim/d/depth_first_search_iterative.nim) |
| Odin | [`odin/d/depth_first_search_iterative.odin`](../../../odin/d/depth_first_search_iterative.odin) |
| Rust | [`rust/d/depth_first_search_iterative.rs`](../../../rust/d/depth_first_search_iterative.rs) |
| V | [`v/d/depth_first_search_iterative.v`](../../../v/d/depth_first_search_iterative.v) |
| Zig | [`zig/d/depth_first_search_iterative.zig`](../../../zig/d/depth_first_search_iterative.zig) |
