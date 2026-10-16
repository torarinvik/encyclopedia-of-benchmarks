# Bellman–Ford Pair Query

This package ports the Go `Graph.BellmanFord(start, end)` operation, which answers one source-to-target query and reports whether the target is reachable, its distance, and any negative cycle reachable from the source. It has a different ABI from the all-destinations [`bellman_ford`](../bellman_ford/README.md) package.

Input is `[vertex_count, edge_count, source, target, (from, to, weight)...]` with zero-based vertices and directed signed-weight edges. The graph has 1 through 64 vertices and at most 256 edge records. An ordered endpoint pair is stored once, so a later parallel-edge record replaces the previous weight. After that normalization, at most 128 distinct directed pairs are allowed. Weights are in `[-1000, 1000]`. These bounds keep every in-place relaxation candidate exactly representable in Go's `float64` implementation and safely within signed 32-bit distance range.

The ports apply the normalized edges in ascending `(from, to)` order for deterministic execution, perform up to `V` in-place relaxation passes, and then check for a still-relaxable edge whose origin is reachable from the source. A negative cycle in an unreachable component does not affect the result. The edge order differs from Go's map iteration order, but the bounded `V` passes yield the same shortest distance or source-reachable negative-cycle result.

Success returns 24 bytes encoding three little-endian signed 64-bit values: `[status, reachable, distance]`. Status `0` means no source-reachable negative cycle; `reachable` is `0` or `1`. An unreachable target is normalized to `[0, 0, 0]`; a reachable target is `[0, 1, shortest_distance]`. A reachable negative cycle returns `[-1, 0, 0]`, even when the queried target is otherwise unreachable. Malformed input returns `-1` with no output, and an absent or undersized output buffer returns `-2`.

| Language | Port |
|---|---|
| C | [`c/b/bellman_ford_pair.c`](../../../c/b/bellman_ford_pair.c) |
| C3 | [`c3/b/bellman_ford_pair.c3`](../../../c3/b/bellman_ford_pair.c3) |
| C++ | [`cpp/b/bellman_ford_pair.cpp`](../../../cpp/b/bellman_ford_pair.cpp) |
| Elisa | [`elisa/b/bellman_ford_pair.elisa`](../../../elisa/b/bellman_ford_pair.elisa) |
| Nim | [`nim/b/bellman_ford_pair.nim`](../../../nim/b/bellman_ford_pair.nim) |
| Odin | [`odin/b/bellman_ford_pair.odin`](../../../odin/b/bellman_ford_pair.odin) |
| Rust | [`rust/b/bellman_ford_pair.rs`](../../../rust/b/bellman_ford_pair.rs) |
| V | [`v/b/bellman_ford_pair.v`](../../../v/b/bellman_ford_pair.v) |
| Zig | [`zig/b/bellman_ford_pair.zig`](../../../zig/b/bellman_ford_pair.zig) |

Pinned source: [TheAlgorithms/Go `graph/bellmanford.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/graph/bellmanford.go). Its graph stores one weight for each ordered pair, uses up to `V` in-place passes, detects source-reachable negative cycles, and returns one target's reachability and distance. See [`workload.json`](workload.json) for reachable, unreachable, negative-cycle, parallel-edge, bound, and malformed cases.
