# Matroid Intersection

This profile finds a maximum-cardinality common independent set for a graphic
matroid and a partition matroid. The selected graph edges must form a forest,
and each edge color has a supplied capacity. The implementation builds an
exchange graph, finds a shortest augmenting path with breadth-first search,
toggles its edge IDs, and repeats until no augmentation exists. It returns
only the maximum cardinality, so no tie-breaking convention is required.

The profile is distinct from minimum spanning tree algorithms, which impose
only graphic independence and use weight-ordered greedy selection. It is also
distinct from specialized bipartite matching algorithms: this implementation
uses a generic exchange-graph augmentation over the two independence tests.

## Contract

The `i64_array_scalar` input is
`[V, M, C, capacity_0, ..., capacity_(C-1), (u, v, color)_0, ...]`.
There are exactly `3 + C + 3*M` signed 64-bit words. Bounds are
`1 <= V <= 10`, `0 <= M <= 20`, and `1 <= C <= 8`. Each capacity is in
`0..20`, endpoints are in `0..V-1`, and colors are in `0..C-1`. Self-loops
are valid input edges but cannot be selected into a forest. Parallel edges
are distinct ground elements and any two parallel edges together form a
cycle. Invalid frames, out-of-domain values, and null input return `-1`.

The answer is the largest edge-set cardinality satisfying both constraints:
the selected edges are acyclic, and each color `c` occurs at most
`capacity_c` times. A forest on at most ten vertices has rank at most nine,
so valid results are in `0..9`. At most 72 words are read, including one
parseable trailing word used to check exact frame rejection.

For each augmentation, outside edges addable to the current forest seed BFS.
An outside-to-inside exchange is allowed when removing the inside edge and
adding the outside edge preserves all color quotas; an inside-to-outside
exchange is allowed when the same swap preserves a forest. An outside edge
that can be added under the partition quotas is a sink. Toggling the edges on
a shortest source-to-sink path increases the common independent set by one.
Each oracle rebuilds a tiny DSU or color-count array from the current set. The
bounded profile has worst-case time `O(V M^2 (V+M))` and at most 440 bytes of
fixed algorithm workspace, including a possible by-value membership snapshot,
under the documented 64-bit ID layout.

The primary reference follows the exchange-graph algorithm. The independent
oracle enumerates every one of the at most `2^20` subsets and directly checks
acyclicity and color capacities. The exchange-path fixture first admits edge
`(0,1,color 0)`. To also select `(0,1,color 1)`, the algorithm must exchange
out the selected edge for the disjoint `(2,3,color 0)` edge: the shortest path
is outside edge → selected edge → alternate outside edge. The workload also
covers cycles, parallel edges, loops, disconnected forests, quota boundaries,
null input, and malformed frames.

## Provenance

The algorithm idea is attributed to Algovault's pinned
[`matroid_intersection.cpp`](https://github.com/sgtlaugh/algovault/blob/becacfa9f85dc6b5869fb5d8262635ed9caae578/code_library/graphs/matroid_intersection.cpp)
at commit `becacfa9f85dc6b5869fb5d8262635ed9caae578` (MIT). Only the generic
exchange-graph idea is used; all contract details, references, cases, and
ports are independently written. See [`RIGHTS.md`](RIGHTS.md) and
[`INVENTORY.md`](INVENTORY.md).

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/m/matroid_intersection.c`](../../../c/m/matroid_intersection.c) |
| C3 | [`c3/m/matroid_intersection.c3`](../../../c3/m/matroid_intersection.c3) |
| C++ | [`cpp/m/matroid_intersection.cpp`](../../../cpp/m/matroid_intersection.cpp) |
| Elisa | [`elisa/m/matroid_intersection.elisa`](../../../elisa/m/matroid_intersection.elisa) |
| Mojo | [`mojo/m/matroid_intersection.mojo`](../../../mojo/m/matroid_intersection.mojo) |
| Nim | [`nim/m/matroid_intersection.nim`](../../../nim/m/matroid_intersection.nim) |
| Odin | [`odin/m/matroid_intersection.odin`](../../../odin/m/matroid_intersection.odin) |
| Rust | [`rust/m/matroid_intersection.rs`](../../../rust/m/matroid_intersection.rs) |
| V | [`v/m/matroid_intersection.v`](../../../v/m/matroid_intersection.v) |
| Zig | [`zig/m/matroid_intersection.zig`](../../../zig/m/matroid_intersection.zig) |
