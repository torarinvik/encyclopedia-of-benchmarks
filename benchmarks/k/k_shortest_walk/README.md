# K Shortest Walk

Rank the directed walks from a source to a target by total weight. The
benchmark follows the task in [Library Checker](https://judge.yosupo.jp/problem/k_shortest_walk),
with the input and output shape described by its
[task specification](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/graph/k_shortest_walk/task.md).
The task definition is used for taxonomy only; these ports and the oracle are
independently written. No statement text or source code has been copied.

## Contract

Input is `[n, m, s, t, k, (u, v, w)*m]`: `1 <= n <= 6`, `0 <= m <= 12`,
`1 <= k <= 8`, valid zero-based endpoints, and weights from `0` through
`1000`. The graph is a directed multigraph. Parallel arcs are distinct walks;
walks may revisit vertices and reuse edges. The empty walk from a vertex to
itself has weight zero. Output contains exactly `k` signed 64-bit distances in
little-endian order. Equal-cost walks each contribute a value. Missing ranks
are encoded as `-1`. Invalid input returns `-1`; a null output or capacity
below `8*k` returns `-2`. The output remains untouched on errors.

## Algorithm and bounds

The measured algorithm uses a sorted frontier of walk prefixes. It expands at
most the first `k` popped walks at each vertex. With nonnegative weights, a
walk using a later prefix to some vertex cannot rank among the first `k`
walks to the target: the first `k` prefixes can each be extended by the same
remaining suffix to produce `k` distinct walks no more expensive. Each
parallel arc is stored as its own outgoing edge, and popped target walks are
expanded until all requested ranks have been found.

There are at most `k*m + 1` frontier entries, so the bounded sorted-array
frontier takes `O((K*M)^2 + K*N + M)` time and `O(K*M + N + M + K)` space.
The independent oracle uses a different method: dynamic programming by exact
walk edge count, retaining the `k` lowest costs for each vertex and length.
Any walk with at least `K*N` edges repeats a vertex at least `K+1` times;
replacing each earlier prefix with the suffix after the last visit gives `K`
distinct walks no more expensive, so no such walk is needed among the first
`K` ranks. This bounds the oracle to at most `K*N-1` edges.

See [`workload.json`](workload.json), the exact-length
[dynamic-programming oracle](../../k_shortest_walk_oracle.py), and the
[static fixture/source checker](../../k_shortest_walk_verifier.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/k/k_shortest_walk.c`](../../../c/k/k_shortest_walk.c) |
| C3 | [`c3/k/k_shortest_walk.c3`](../../../c3/k/k_shortest_walk.c3) |
| C++ | [`cpp/k/k_shortest_walk.cpp`](../../../cpp/k/k_shortest_walk.cpp) |
| Elisa | [`elisa/k/k_shortest_walk.elisa`](../../../elisa/k/k_shortest_walk.elisa) |
| Nim | [`nim/k/k_shortest_walk.nim`](../../../nim/k/k_shortest_walk.nim) |
| Odin | [`odin/k_shortest_walk.odin`](../../../odin/k_shortest_walk.odin) |
| Rust | [`rust/k/k_shortest_walk.rs`](../../../rust/k/k_shortest_walk.rs) |
| V | [`v/k/k_shortest_walk.v`](../../../v/k/k_shortest_walk.v) |
| Zig | [`zig/k/k_shortest_walk.zig`](../../../zig/k/k_shortest_walk.zig) |
