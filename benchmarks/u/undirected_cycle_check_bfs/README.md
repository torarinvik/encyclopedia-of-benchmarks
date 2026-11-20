# Undirected cycle check with breadth-first search — draft

This profile detects a cycle in an undirected graph by exploring each component
with a FIFO queue of vertices and recording each vertex's parent. An edge to a
previously discovered vertex other than the current vertex's parent identifies
a cycle; a self-loop is a cycle. Mark vertices when enqueued. Neighbors are
scanned in increasing vertex order. This differs from
[`undirected_cycle_check`](../undirected_cycle_check/README.md), which uses a
stack, while retaining its input and output contract for comparison.

The `i64_array_scalar` input is `[n,m,u0,v0,...]`, with `0 <= n <= 32`,
`0 <= m <= 256`, exactly `2+2*m` signed i64 words and endpoints in `[0,n)`.
Duplicate undirected edges are invalid, including repeated loops. Return `-1`
for invalid or null input, `1` for a cycle, and `0` otherwise. Validate the
entire graph before starting the search. A fixed 32-by-32 adjacency matrix
gives O(n²+m) time and O(n²) storage; the FIFO holds at most n vertices.

The algorithm idea comes from the breadth-first undirected cycle method in
[TheAlgorithms/Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/graph/detect_cycle.rs)
(MIT). The contract and implementations are independently written; no source
code or fixtures are copied. The shared union-find reference for the existing
profile can independently check this contract.

Ten language drafts, a [workload](workload.json), shared union-find oracle, and
scalar runner/verifier registration are present. The verifier draft shares the
same graph corpus as the stack variant, including loops, disconnected graphs,
duplicate edges, maximum bounds, and null inputs. The workload includes a
32-vertex star and path to exercise wide and narrow queues, a cycle near the
end of a path, and a self-loop at the last vertex. The verifier draft
also checks fixture metadata, the ten source paths, and invariance under
vertex relabeling, reversing edge order, and reversing endpoint orientation. It includes maximum-frame
cases with invalid final edges after an earlier cycle. A 256-edge complete
bipartite workload reaches the input bound. Nothing has been
compiled or executed; correctness and integration remain unverified.

| Language | Draft |
|---|---|
| C | [C](../../../c/u/undirected_cycle_check_bfs.c) |
| C3 | [C3](../../../c3/u/undirected_cycle_check_bfs.c3) |
| C++ | [C++](../../../cpp/u/undirected_cycle_check_bfs.cpp) |
| Elisa | [Elisa](../../../elisa/u/undirected_cycle_check_bfs.elisa) |
| Mojo | [Mojo](../../../mojo/u/undirected_cycle_check_bfs.mojo) |
| Nim | [Nim](../../../nim/u/undirected_cycle_check_bfs.nim) |
| Odin | [Odin](../../../odin/u/undirected_cycle_check_bfs.odin) |
| Rust | [Rust](../../../rust/u/undirected_cycle_check_bfs.rs) |
| V | [V](../../../v/u/undirected_cycle_check_bfs.v) |
| Zig | [Zig](../../../zig/u/undirected_cycle_check_bfs.zig) |
