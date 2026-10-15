# Topological sort

This benchmark orders the vertices of a directed acyclic graph with Kahn's algorithm. A directed cycle returns an error status.

## Contract

- The input is a signed 64-bit array encoded as [vertex_count, source_0, destination_0, ...].
- Graphs contain 0–64 vertices and at most 32 directed edges, within the shared array-output ABI's 66-value input limit.
- Vertex IDs are integers from 0 through vertex_count - 1. Duplicate edges are coalesced.
- Kahn's queue starts with zero-indegree vertices in ascending ID order. Each popped vertex scans its outgoing neighbors in ascending ID order. The returned order is deterministic.
- On success, the function returns the vertex count and writes one vertex ID byte per vertex. The empty graph succeeds with an empty order.
- A cycle, including a self-loop, returns -1 and writes no output. Malformed input, an invalid endpoint, insufficient output capacity returns -2 and writes no output.
- Implementations use fixed-size stack storage and portable integer operations.

## Source mapping

This package is the Kahn variant. Its deterministic FIFO contract matches the pinned Rust implementation and the Kahn-specific C++ sources in [`topological_sort_by_kahns_algo`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/graph/topological_sort_by_kahns_algo.cpp) and its [additional repository mirror](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/graph/topological_sort_by_kahns_algo.cpp). The C# `SortKahn` method is also a Kahn implementation.

The pinned C and C++ `topological_sort` sources, C# `Sort`, Java, JavaScript, Python `sorts/topological_sort.py`, R, Ruby, and Python `g_topological_sort.py` use DFS postorder variants; they map to [`topological_sort_dfs`](../topological_sort_dfs/README.md). The original C example has a 40-vertex limit and does not detect cycles. The C++ visited-only DFS does not reliably detect back edges. The Rust implementation uses Kahn's algorithm and reports cycles, while the Kahn-specific C++ source does not report cycles; the shared contract normalizes cycle behavior and deterministic order.

The Go `topological` candidate is recorded as a reviewed invalid source and is not aliased to either package. Its helper treats directed input like an undirected graph and records pre-order traversal without a global finished state, so it can emit a vertex before one of its prerequisites or emit duplicates.

## Workload and verification

workload.json includes empty and isolated graphs, both C++ examples, a chain, branching and duplicate-edge graphs, cycles, and maximum-size inputs. The verifier exhausts all directed graphs through three vertices, checks deterministic random graphs and malformed inputs, and validates the emitted order against an independent topological-order oracle.

Build with the i64_array_bytes_output ABI family. benchmarks/run_i64_array_bytes_output.py records measurements and benchmarks/verify_topological_sort.py verifies all nine language ports.
