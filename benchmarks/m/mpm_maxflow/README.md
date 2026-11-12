# MPM maximum flow

Compute the maximum flow in a bounded directed capacitated graph using the
Malhotra–Pramodh-Kumar–Maheshwari (MPM) algorithm. Each phase builds a BFS
level graph. It repeatedly chooses the live vertex with minimum potential,
routes that amount from the source to the vertex and on to the sink, then
removes the saturated vertex from the level graph.

## Contract

Input is `[N, M, source, sink, (from, to, capacity)*M]` with 1-based vertex
IDs, `2 <= N <= 8`, `0 <= M <= 24`, distinct source and sink, and capacities
in `[0,100]`. Self-loops are invalid; parallel and antiparallel arcs are
allowed. The maximum sum of input capacities is 2400. Output is the maximum
flow as a signed 64-bit integer. Invalid input returns `-1`.

## Algorithm and distinctness

For each residual BFS phase, only arcs from level `d` to `d+1` form the
layered network. A vertex's inner potential is its active incoming residual
capacity, and its outer potential is its active outgoing residual capacity.
The reference vertex minimizes the lesser of those two values. The ports
route that potential to and from the terminals, update forward and reverse
residual capacities, and delete the reference vertex. This differs from
Dinic's per-vertex blocking-flow DFS and push-relabel's excess/relabel
process.

The reference MPM profile runs in `O(V^3)` time. Its residual and layered
network storage is `O(V^2 + M)` including the packed input edges; this
workload bounds the explicit scratch workspace to 2,048 bytes for fixed
8-by-8 matrices, per-vertex arrays, and recursive push frames. The independent
oracle enumerates every source-side cut and returns its minimum capacity.

Algorithm description: [CP-Algorithms — MPM maximum-flow algorithm](https://cp-algorithms.com/graph/mpm.html).
The ports implement the described method independently; they do not copy
the article's reference implementation.

[`workload.json`](workload.json) covers parallel and antiparallel arcs,
internal bottlenecks, disconnected terminals, zero capacities, alternate
terminals, malformed graphs, and capacity boundaries.

## Implementations

| Language | Port |
|---|---|
| C | [`c/m/mpm_maxflow.c`](../../../c/m/mpm_maxflow.c) |
| C3 | [`c3/m/mpm_maxflow.c3`](../../../c3/m/mpm_maxflow.c3) |
| C++ | [`cpp/m/mpm_maxflow.cpp`](../../../cpp/m/mpm_maxflow.cpp) |
| Elisa | [`elisa/m/mpm_maxflow.elisa`](../../../elisa/m/mpm_maxflow.elisa) |
| Mojo | [`mojo/m/mpm_maxflow.mojo`](../../../mojo/m/mpm_maxflow.mojo) |
| Nim | [`nim/m/mpm_maxflow.nim`](../../../nim/m/mpm_maxflow.nim) |
| Odin | [`odin/m/mpm_maxflow.odin`](../../../odin/m/mpm_maxflow.odin) |
| Rust | [`rust/m/mpm_maxflow.rs`](../../../rust/m/mpm_maxflow.rs) |
| V | [`v/m/mpm_maxflow.v`](../../../v/m/mpm_maxflow.v) |
| Zig | [`zig/m/mpm_maxflow.zig`](../../../zig/m/mpm_maxflow.zig) |
