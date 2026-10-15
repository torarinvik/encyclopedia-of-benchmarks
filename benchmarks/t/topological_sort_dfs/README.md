# Topological sort with depth-first search

This benchmark orders a directed graph by depth-first search finishing times. It is kept separate from [`topological_sort`](../topological_sort/README.md), which measures FIFO Kahn ordering. These strategies can return different valid topological orders for the same graph.

## Contract

- Input is a signed 64-bit array encoded as `[vertex_count, source_0, destination_0, ...]`.
- Graphs contain 0–40 vertices and at most 32 directed edges. The 40-vertex bound preserves the limit in the pinned C source and fits the shared 66-value array-output ABI.
- Vertex IDs range from 0 through `vertex_count - 1`; duplicate edges are coalesced.
- DFS starts roots in ascending vertex ID order and scans each vertex's outgoing neighbors in ascending ID order. A three-color state detects edges to active vertices. The output is the reverse of DFS finishing order.
- On success, the function returns the vertex count and writes one vertex ID byte per vertex. An empty graph succeeds with an empty order.
- A cycle, including a self-loop, returns -1 and writes no output. Malformed input, an invalid endpoint, or insufficient output capacity returns -2 and writes no output.

All nine ports use bounded adjacency bitsets and an explicit DFS frame stack. They therefore share the same deterministic traversal and cycle behavior without relying on recursion limits.

## Source mapping

The benchmark ports cover the DFS source family:

- [C `topological_sort.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/graphs/topological_sort.c)
- [C++ `topological_sort.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/graph/topological_sort.cpp) and [C++ additional repository mirror](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/graph/topological_sort.cpp)
- [C# `Sort`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Graph/TopologicalSort.cs) (the same class also has a Kahn method)
- [Java `TopologicalSort.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/sorts/TopologicalSort.java)
- [JavaScript `TopologicalSort.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Sorts/TopologicalSort.js)
- [Python `sorts/topological_sort.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/sorts/topological_sort.py) and [Python `g_topological_sort.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/g_topological_sort.py)
- [R `topological_sort.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/sorting_algorithms/topological_sort.r)
- [Ruby `topological_sort.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/graphs/topological_sort.rb)

The pinned C and C++ sources use visited-only DFS and do not reliably detect back edges; the C implementation also fixes its storage at 40 vertices. This benchmark makes the ordering, limits, duplicate-edge handling, and cycle behavior explicit. The Go `topological` candidate is excluded from the mapping because its DFS helper mutates adjacency and lacks global finished-state tracking, which can yield invalid orders.

## Workload and measurement

`workload.json` includes empty and isolated graphs, both C++ examples, chains, branching and disconnected graphs, duplicate edges, cycles, malformed input, invalid endpoints, and maximum-size inputs. Build with the `i64_array_bytes_output` ABI family. The shared runner's static oracle supports both `topological_sort` and `topological_sort_dfs`.
