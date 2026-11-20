# Shortest walk visiting all vertices

Given a connected undirected simple graph, return the minimum number of edge
traversals in a walk that visits every vertex. The walk may start and finish
anywhere, and it may revisit vertices and edges. This is not a Hamiltonian
path: repeated visits can be necessary.

## Bounded scalar contract

Input is `[N,M,(u,v)*M]`, with `1 <= N <= 10`, `0 <= M <= 45`, and each
undirected edge listed once. Edges have distinct endpoints in `0..N-1`, and
the graph must be connected. The packed length must be exactly `2 + 2*M`; the
maximum valid and parseable lengths are 92 and 93 words. A null pointer,
disconnected graph, duplicate edge, loop, bad endpoint, malformed header, or
wrong length returns `-1`. A singleton graph returns zero.

The profile is narrower than LeetCode 847's published node bound. It uses the
public title only as a discovery label; this package does not use challenge
text, examples, tests, submissions, or site code.

## Algorithms

The primary ports run multi-source BFS on product states `(v,mask)`. Every
one-vertex state is a distance-zero start. Moving over an edge updates the
visited-vertex mask; the first full-mask state removed from the queue gives
the shortest covering walk. With at most ten vertices, there are at most
`N*2^N = 10,240` states and `O(2^N*(N+M))` time.

The independent oracle first computes all-pairs unweighted distances with
Floyd–Warshall. It then uses min-plus subset DP to choose an order of the
vertices and pays the shortest-path distance between consecutive choices.
The DP describes a walk in the metric closure, so intermediate vertices may
be revisited or covered early. It takes `O(N^3 + N^2*2^N)` time and
`O(N*2^N + N^2)` space. This reference differs structurally from queue
traversal of the product graph.

## References

- [LeetCode 847 public title page](https://leetcode.com/problems/shortest-path-visiting-all-nodes/) — title-only discovery reference.
- [CP-Algorithms: Breadth First Search](https://cp-algorithms.com/graph/breadth-first-search.html) — shortest paths in an unweighted graph and state-space construction.
- [CP-Algorithms: Floyd–Warshall](https://cp-algorithms.com/graph/all-pair-shortest-path-floyd-warshall.html) — independent shortest-path closure.

See [`workload.json`](workload.json), the [primary oracle](primary_oracle.py),
and the [independent oracle](independent_oracle.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/s/shortest_path_visiting_all_nodes.c`](../../../c/s/shortest_path_visiting_all_nodes.c) |
| C3 | [`c3/s/shortest_path_visiting_all_nodes.c3`](../../../c3/s/shortest_path_visiting_all_nodes.c3) |
| C++ | [`cpp/s/shortest_path_visiting_all_nodes.cpp`](../../../cpp/s/shortest_path_visiting_all_nodes.cpp) |
| Elisa | [`elisa/s/shortest_path_visiting_all_nodes.elisa`](../../../elisa/s/shortest_path_visiting_all_nodes.elisa) |
| Mojo | [`mojo/s/shortest_path_visiting_all_nodes.mojo`](../../../mojo/s/shortest_path_visiting_all_nodes.mojo) |
| Nim | [`nim/s/shortest_path_visiting_all_nodes.nim`](../../../nim/s/shortest_path_visiting_all_nodes.nim) |
| Odin | [`odin/s/shortest_path_visiting_all_nodes.odin`](../../../odin/s/shortest_path_visiting_all_nodes.odin) |
| Rust | [`rust/s/shortest_path_visiting_all_nodes.rs`](../../../rust/s/shortest_path_visiting_all_nodes.rs) |
| V | [`v/s/shortest_path_visiting_all_nodes.v`](../../../v/s/shortest_path_visiting_all_nodes.v) |
| Zig | [`zig/s/shortest_path_visiting_all_nodes.zig`](../../../zig/s/shortest_path_visiting_all_nodes.zig) |

The static inventory is [`verify_workload.py`](verify_workload.py); it was not
executed.
