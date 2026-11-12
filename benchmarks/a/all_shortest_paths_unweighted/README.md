# All shortest paths in an unweighted graph

This package enumerates every shortest path between two vertices in a bounded
undirected unweighted simple graph. The `Word Ladder II` title/topic entry in
the public LeetCode index was used only to discover this algorithm family; the
benchmark is a general graph operation and does not use site problem content.

## Contract

The exported symbol is `all_shortest_paths_unweighted(input, length, output,
capacity) -> i64` in the `i64_array_bytes_output` ABI. Input is
`[vertex_count,edge_count,source,target,(u,v)*edge_count]`. There are 1 to 16
vertices and 0 to 64 undirected edges. Self-edges and duplicate unordered
edges are invalid. The exact input length is `4 + 2*edge_count`; 132 values is
the largest valid input, and one extra value is accepted for parsing before
the frame is rejected.

BFS builds source distances and a predecessor DAG. A reverse pass from the
destination marks only DAG vertices that participate in a shortest answer.
Forward DFS visits successor IDs in increasing order. Each path is emitted as
one byte per vertex ID, followed by `0xff`; this makes the complete result
lexicographic by vertex sequence. The function returns the path count. An
unreachable target returns zero with no bytes. If source equals target, the
single path is that vertex followed by the terminator.

With 16 vertices, the largest possible product of nonempty intermediate BFS
layer sizes is `3*3*3*3*2 = 162`, so the path-count cap is 162. Combining the
layer bound with path length gives a maximum encoded output of 1296 bytes,
which is attained by complete consecutive layers of sizes 3, 3, 3, 3, and 2.
The fixed workspace contract is 4096 bytes. Malformed input returns `-1`;
null output or capacity below the actual output length returns `-2`, without
writing. A non-null output pointer is required even for an empty result.

The primary takes `O(N^2 + P*N^2 + output_bytes)` time, where `P` is the
number of shortest paths, and `O(N^2 + output_bytes)` space. It scans the
bounded vertex set while traversing each prefix of the predecessor DAG. The
independent Floyd-Warshall oracle takes `O(N^3 + P*N^2 + output_bytes)` time.

## Distinction from existing packages

[`word_ladder`](../../w/word_ladder/README.md) returns only shortest length;
[`word_ladder_dfs`](../../w/word_ladder_dfs/README.md) returns one first DFS
path. [`all_paths_from_source_to_target`](../all_paths_from_source_to_target/README.md)
enumerates every simple path, including longer paths. [`yens_kshortest_paths`](../../y/yens_kshortest_paths/README.md)
orders a bounded prefix of loopless paths by weighted cost using Yen's
candidate-generation algorithm. This package instead enumerates all and only
the unweighted shortest paths from a BFS predecessor DAG.

## Workload and provenance

[`workload.json`](workload.json) covers equal-length alternatives, eight
shortest paths, a longer non-shortest route, unreachable and equal endpoints,
malformed graph records, null pointers, and output-capacity errors. The
primary oracle uses BFS and a predecessor DAG; the independent oracle uses
all-pairs Floyd-Warshall distances to guide a separate traversal.

The LeetCode public title/topic listing is a discovery index only. No task
statement, constraints, examples, tests, submissions, or site code were used.
See [`RIGHTS.md`](RIGHTS.md) for the provenance note.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/all_shortest_paths_unweighted.c`](../../../c/a/all_shortest_paths_unweighted.c) |
| C3 | [`c3/a/all_shortest_paths_unweighted.c3`](../../../c3/a/all_shortest_paths_unweighted.c3) |
| C++ | [`cpp/a/all_shortest_paths_unweighted.cpp`](../../../cpp/a/all_shortest_paths_unweighted.cpp) |
| Elisa | [`elisa/a/all_shortest_paths_unweighted.elisa`](../../../elisa/a/all_shortest_paths_unweighted.elisa) |
| Mojo | [`mojo/a/all_shortest_paths_unweighted.mojo`](../../../mojo/a/all_shortest_paths_unweighted.mojo) |
| Nim | [`nim/a/all_shortest_paths_unweighted.nim`](../../../nim/a/all_shortest_paths_unweighted.nim) |
| Odin | [`odin/a/all_shortest_paths_unweighted.odin`](../../../odin/a/all_shortest_paths_unweighted.odin) |
| Rust | [`rust/a/all_shortest_paths_unweighted.rs`](../../../rust/a/all_shortest_paths_unweighted.rs) |
| V | [`v/a/all_shortest_paths_unweighted.v`](../../../v/a/all_shortest_paths_unweighted.v) |
| Zig | [`zig/a/all_shortest_paths_unweighted.zig`](../../../zig/a/all_shortest_paths_unweighted.zig) |
