# Articulation points

This benchmark finds the cut vertices of an undirected graph with Tarjan's discovery-time and low-link rules. It scans every connected component. Results are returned as zero-based vertex IDs in ascending order, so the output is deterministic.

The pinned C# implementation scans all vertices and returns a set. The Python implementation stores vertex labels in its `low` array instead of discovery times, and the Go implementation starts its DFS only at vertex 0. Those details can miss or misclassify articulation points on some inputs. These ports use discovery timestamps and process disconnected graphs correctly while preserving the shared cut-vertex meaning.

## Contract

- Input is `[vertex_count, edge_count, (left, right) * edge_count]` with zero-based IDs.
- There are 0–64 vertices and 0–2,047 packed edges. Endpoints must be valid. Edges are undirected; repeated edges are coalesced, and self-loops are allowed.
- The exact input length is `2 + 2 * edge_count`. Invalid input returns `-1`.
- The output contains each articulation point as one byte, in ascending vertex order. A graph with no articulation points returns an empty byte sequence. The result is the output byte count.
- If the output buffer is too small, or is null for a nonempty result, the function returns `-2` without writing output. An empty result accepts a null output buffer.

The bitset-adjacency implementations scan all vertex pairs during DFS, so their
time is O(m+n²) and their stored adjacency and traversal state use O(n) machine
words for the bounded 64-vertex graph. This differs from the O(n+m) bound of an
adjacency-list implementation.

[`workload.json`](workload.json) covers empty and disconnected graphs, root handling, cycles, tails, duplicate edges, self-loops, a maximum-size path, and malformed inputs. Runtime verification is pending.

The independent [component-deletion oracle](independent_oracle.py) counts
components before and after deleting each vertex. The verifier source includes
all simple graphs on up to five vertices, a maximum-size path, duplicate edges,
self-loops, and output-buffer cases. Neither the oracle nor the suite changes
have been executed.

## Pinned sources

- [C# ArticulationPoints.cs](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Graph/ArticulationPoints.cs)
- [Python articulation_points.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/articulation_points.py)
- [Go articulationpoints.go](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/graph/articulationpoints.go)
