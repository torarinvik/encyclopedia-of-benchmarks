# Strong orientation

For each undirected graph, orient every input edge so that the resulting
directed graph has the minimum possible number of strongly connected
components. The package follows CP-Algorithms' DFS orientation: each DFS tree
edge points from parent to child; each edge first encountered from a vertex
to an already visited vertex points in that traversal direction. Its minimum
SCC count is the number of original connected components plus the number of
bridges.

## Contract

The packed input is `[n, m, (u, v) * m]`. Vertices are numbered from zero;
`1 <= n <= 64`, `0 <= m <= 128`, and every endpoint is in `[0,n)`. Self-loops
and parallel edges are allowed and retain their input edge IDs. Input length
must be exactly `2 + 2*m` words. DFS roots are examined by increasing vertex
ID. Each vertex's adjacency entries are visited in input edge order, including
both incidences of a self-loop.

The output is a little-endian signed i64 array `[minimum_scc_count, d_0, ...,
d_(m-1)]`. For edge `(u,v)` in the input, `d_i = 1` means `u -> v` and
`d_i = -1` means `v -> u`; a self-loop uses `1`. The direction entries are
indexed by original edge order. There is always one count word, even when
`m=0`, so the output length is `8*(m+1)` bytes and the maximum is 1,032 bytes.
Invalid input returns `-1`; a null or undersized output buffer returns `-2`
without writing any bytes.

## Distinctness

[`bridges`](../../b/bridges/README.md) returns the static cut-edge set without
orienting the graph. [`online_bridge_finding`](../../o/online_bridge_finding/README.md)
maintains bridge counts under edge insertions. [`gbbs_biconnectivity`](../../g/gbbs_biconnectivity/README.md)
assigns vertex-biconnected edge-block labels, and the local 2-edge and
3-edge-connected packages return different subgraph or component results.
[`st_numbering`](../st_numbering/README.md) ranks vertices in a biconnected graph
with designated terminals; it does not orient all graph edges. None of these
produces a minimum-SCC orientation of every edge.

This is a clean-room bounded port of the [CP-Algorithms strong orientation
algorithm](https://cp-algorithms.com/graph/strong-orientation.html) and its
minimum-SCC extension. The independent oracle uses iterative DFS to reproduce
the specified deterministic directions, edge-deletion connectivity counts
for the minimum, and a separate directed SCC pass to check the orientation
certificate. See [`workload.json`](workload.json) and
[`benchmarks/strong_orientation_oracle.py`](../../strong_orientation_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/strong_orientation.c`](../../../c/s/strong_orientation.c) |
| C3 | [`c3/s/strong_orientation.c3`](../../../c3/s/strong_orientation.c3) |
| C++ | [`cpp/s/strong_orientation.cpp`](../../../cpp/s/strong_orientation.cpp) |
| Elisa | [`elisa/s/strong_orientation.elisa`](../../../elisa/s/strong_orientation.elisa) |
| Mojo | [`mojo/s/strong_orientation.mojo`](../../../mojo/s/strong_orientation.mojo) |
| Nim | [`nim/s/strong_orientation.nim`](../../../nim/s/strong_orientation.nim) |
| Odin | [`odin/s/strong_orientation.odin`](../../../odin/s/strong_orientation.odin) |
| Rust | [`rust/s/strong_orientation.rs`](../../../rust/s/strong_orientation.rs) |
| V | [`v/s/strong_orientation.v`](../../../v/s/strong_orientation.v) |
| Zig | [`zig/s/strong_orientation.zig`](../../../zig/s/strong_orientation.zig) |
