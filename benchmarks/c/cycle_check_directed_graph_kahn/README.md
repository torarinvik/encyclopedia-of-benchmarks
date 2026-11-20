# Directed graph cycle check (Kahn's algorithm)

This benchmark checks for a directed cycle by repeatedly removing zero-indegree vertices. If fewer than all declared vertices can be removed, the remaining graph contains a cycle.

## Contract

- Input is a signed 64-bit array encoded as `[vertex_count, source_0, destination_0, ...]`.
- Graphs contain 0–64 vertices and at most 32 directed edges. Vertices are numbered from `0` through `vertex_count - 1`; isolated vertices are included by the vertex count.
- Duplicate edges are coalesced. A self-loop is a cycle. Disconnected components are all examined.
- Return `1` when a cycle exists, `0` when the graph is acyclic, and `-1` for malformed input or an endpoint outside the declared vertex range.
- Validate every edge before searching, so a malformed later edge returns `-1` even if an earlier edge forms a cycle.
- Implementations use bounded, fixed-size adjacency bitsets and portable scalar operations. The queue begins with zero-indegree vertices in ascending ID order and scans neighbors in ascending ID order. This representation gives the bounded ports an `O(V²)` worst-case cost, with `V ≤ 64`.

The pinned C++ `isCyclicBFS` method uses Kahn's zero-indegree queue. The two pinned C++ repositories contain the same implementation. Their three-state depth-first variant aliases [`check_cycle`](../check_cycle/README.md); this package preserves the distinct Kahn traversal.

## Workload

[`workload.json`](workload.json) covers representative acyclic and cyclic
graphs, duplicate edges, maximum bounds, and malformed input. Its framing and
limits differ from [`check_cycle`](../check_cycle/README.md), so the two
workloads are not directly interchangeable. The scalar suite now has a draft
[independent transitive-closure reference](independent_oracle.py) and verifier
cases for small directed graphs and null inputs. Ten language drafts are
present; the new reference, verifier wiring, and recent V and Mojo fixes remain
uncompiled and unexecuted.
On their shared domain the verifier draft compares this profile's reference
with the separate directed DFS benchmark's oracle after adapting the input
framing. It also specifies maximum-length, duplicate-edge, and high-bit cases.

## Reviewed TheAlgorithms sources

- [C++ `cycle_check_directed_graph.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/graph/cycle_check_directed_graph.cpp)
- [C++ additional-repository mirror](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/graph/cycle_check_directed_graph.cpp)
- [Rust `detect_cycle.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/graph/detect_cycle.rs) also contains Kahn removal; its graph representation and bounds differ from this profile.
