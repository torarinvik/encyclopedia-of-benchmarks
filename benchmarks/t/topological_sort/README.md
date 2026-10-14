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

The pinned C and C++ sources use recursive depth-first traversal; the Rust source uses Kahn's algorithm and reports cycles. The C example does not detect cycles, and the C++ visited-only DFS does not reliably detect back edges. This benchmark gives all ports the same explicit cycle behavior and deterministic output contract.

## Workload and verification

workload.json includes empty and isolated graphs, both C++ examples, a chain, branching and duplicate-edge graphs, cycles, and maximum-size inputs. The verifier exhausts all directed graphs through three vertices, checks deterministic random graphs and malformed inputs, and validates the emitted order against an independent topological-order oracle.

Build with the i64_array_bytes_output ABI family. benchmarks/run_i64_array_bytes_output.py records measurements and benchmarks/verify_topological_sort.py verifies all nine language ports.
