# Directed girth by breadth-first search

This in-progress benchmark finds the length of a shortest directed cycle in an
unweighted graph. It performs a breadth-first search from each vertex, then
checks edges returning to that start. The [CP-Algorithms BFS applications](https://cp-algorithms.com/graph/breadth-first-search.html)
identify this method; only its algorithmic idea is used here.

The proposed scalar input is `[n,m,(u,v)*m]`, with `1 <= n <= 16`,
`0 <= m <= 64`, zero-based endpoints, and exact length `2+2*m`. Self-loops and
parallel arcs are permitted. Return the smallest cycle length, or zero if no
cycle exists; invalid or null input returns `-1`. The maximum valid and
parseable lengths are 130 and 131 signed i64 words. Time is O(n(n+m)) for an
adjacency-list BFS and O(n+m) auxiliary space. The current drafts coalesce
outgoing arcs into bitsets and scan all possible neighbors, taking O(m+n³)
time and O(n) fixed-width words for this bounded profile.

This is distinct from `check_cycle`, which returns only whether a directed
cycle exists, and `minimum_mean_cycle_karp`, which minimizes weighted average
edge cost. Two independently organized reference drafts, a workload, and
[C](../../../c/d/directed_girth_bfs.c), [C++](../../../cpp/d/directed_girth_bfs.cpp),
[Elisa](../../../elisa/d/directed_girth_bfs.elisa), [Rust](../../../rust/d/directed_girth_bfs.rs),
and [Zig](../../../zig/d/directed_girth_bfs.zig), along with
[C3](../../../c3/d/directed_girth_bfs.c3), [Mojo](../../../mojo/d/directed_girth_bfs.mojo),
[Nim](../../../nim/d/directed_girth_bfs.nim), [Odin](../../../odin/d/directed_girth_bfs.odin),
and [V](../../../v/d/directed_girth_bfs.v) drafts are present. Scalar runner and
verifier wiring includes all directed graphs through four vertices and
independent-reference comparisons, plus arc reversal, vertex relabeling, and
parallel-arc duplication checks for valid fixtures. The workload includes a
16-vertex cycle, a maximum-edge-count graph, and null input at the parser limit.
Static review remains outstanding; nothing has run.
