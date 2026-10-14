# Depth-first search

This benchmark traverses a directed graph from a selected start vertex and returns each reachable vertex once.

## Contract

- The signed 64-bit input array is encoded as [vertex_count, start_vertex, source_0, destination_0, ...].
- Graphs contain 0–64 vertices and at most 32 directed edges, within the shared array-output ABI's 66-value input limit.
- For a nonempty graph, start_vertex must identify a vertex. The empty graph is encoded with start_vertex -1 and no edges.
- Duplicate edges are coalesced. Neighbors are visited in ascending vertex ID order.
- The traversal uses a explicit stack of vertex/neighbor frames simulating recursive preorder. The returned sequence includes only vertices reachable from the start, including the start itself.
- On success, the function returns the reachable vertex count and writes each vertex ID as one byte. An empty graph succeeds with an empty result.
- Malformed input or insufficient output capacity returns -2 and writes no output.
- All nine implementations use fixed-size stack storage and portable integer operations.

The pinned C++ BFS source supports both bidirectional and directed edges and returns the visited set. Rust BFS returns a history only through a requested target. The pinned C++ DFS source builds an undirected graph and recursively prints its traversal; Rust's file named DFS uses a deque as a stack to find a target. The local contract normalizes these APIs to a directed full traversal so both traversal orders can be checked on the same workload.

## Workload and verification

workload.json includes empty and disconnected graphs, branches, cycles, duplicate edges, a self-loop, and maximum-size inputs. The verifier exhausts all directed graphs through three vertices for every start, checks deterministic random and malformed cases, and validates the full visitation order against an independent oracle.

Build with the i64_array_bytes_output ABI family. benchmarks/run_i64_array_bytes_output.py records measurements. Run benchmarks/verify_graph_traversal.py with --algorithm depth_first_search to verify all nine language ports.
