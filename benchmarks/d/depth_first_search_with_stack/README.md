# Depth-first search with a stack

## Contract

Traverse a directed graph from a starting vertex using an explicit LIFO stack. The signed 64-bit input is `[vertex_count, start_vertex, source_0, destination_0, ...]`, with zero-based vertex IDs, at most 64 vertices, and at most 32 directed edges. The empty graph uses `[0, -1]` and returns an empty sequence. Duplicate edges and each source vertex's edge insertion order are preserved.

The algorithm marks a vertex grey when it is pushed. When a grey vertex is popped, it is appended to the output, all of its outgoing neighbors are pushed in input order, and the vertex is marked black. Because the stack is LIFO, later inserted neighbors are considered first. Vertices already black are still pushed as in the source, then skipped when popped. This push-time marking and stack-pop order distinguish this benchmark from [`depth_first_search`](../depth_first_search/README.md), which simulates recursive preorder and sorts neighbors by ID.

Malformed inputs and insufficient output capacity return `-2` without writing bytes. Results contain each reachable vertex once as one byte. The ports use fixed-size storage and portable scalar operations.

## Workload and verification

[`workload.json`](workload.json) covers empty and isolated graphs, reversed sibling order, a cross-edge to an already pending vertex, cycles, self-loops, duplicate edges, disconnected vertices, vertex 63, the 32-edge bound, and malformed input. The checker also exercises insufficient output capacity. Run it without timing the benchmark workload:

```sh
python3 benchmarks/verify_graph_traversal.py --algorithm depth_first_search_with_stack --checker-only
```

## Implementations

| Language | Source |
| --- | --- |
| C | [c/d/depth_first_search_with_stack.c](../../../c/d/depth_first_search_with_stack.c) |
| C3 | [c3/d/depth_first_search_with_stack.c3](../../../c3/d/depth_first_search_with_stack.c3) |
| C++ | [cpp/d/depth_first_search_with_stack.cpp](../../../cpp/d/depth_first_search_with_stack.cpp) |
| Elisa | [elisa/d/depth_first_search_with_stack.elisa](../../../elisa/d/depth_first_search_with_stack.elisa) |
| Nim | [nim/d/depth_first_search_with_stack.nim](../../../nim/d/depth_first_search_with_stack.nim) |
| Odin | [odin/d/depth_first_search_with_stack.odin](../../../odin/d/depth_first_search_with_stack.odin) |
| Rust | [rust/d/depth_first_search_with_stack.rs](../../../rust/d/depth_first_search_with_stack.rs) |
| V | [v/d/depth_first_search_with_stack.v](../../../v/d/depth_first_search_with_stack.v) |
| Zig | [zig/d/depth_first_search_with_stack.zig](../../../zig/d/depth_first_search_with_stack.zig) |

## TheAlgorithms references

Both pinned C++ repositories contain the same `depth_first_search_with_stack.cpp` implementation. Its `addEdge` helper inserts only the source-to-destination edge despite comments describing an undirected graph; the shared contract follows the actual directed adjacency behavior.

- [C++ depth_first_search_with_stack.cpp](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/graph/depth_first_search_with_stack.cpp)
- [C++-Plus-Plus-1 depth_first_search_with_stack.cpp](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/graph/depth_first_search_with_stack.cpp)
