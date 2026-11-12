# Undirected Chinese postman

Find the minimum length of a closed walk that traverses every edge of a
connected, positively weighted, undirected graph at least once. The primary
algorithm computes shortest-path distances between odd-degree vertices and
pairs those vertices at minimum total distance. The route length is the sum of
all original edge weights plus the pairing cost.

## Contract

The scalar ABI symbol is `undirected_chinese_postman`. Input is
`[N,M,(u,v,w)*M]`, with `1<=N<=8`, `0<=M<=12`, simple undirected edges, and
weights in `1..1000`. An empty graph on one vertex is valid and has answer
zero. For `N>1`, the graph must be connected. Self-loops, repeated edges,
disconnected graphs, malformed frames, and out-of-profile values return `-1`.
The result is an exact signed 64-bit integer.

The primary algorithm uses Floyd–Warshall to form the metric closure, then
bitmask dynamic programming to find a minimum pairing of odd-degree vertices.
The independent verifier instead runs Dijkstra directly on the expanded state
space `(current_vertex, covered_edge_mask)`, accepting a state only when it is
back at vertex zero with every edge covered. This checks the route definition
without reusing the pairing reduction. At the profile limits there are at most
8 vertices and 12 edge bits.

## Distinctness and provenance

[`eulerian_path`](../../e/eulerian_path/README.md) and
[`eulerian_trail_undirected_simple`](../../e/eulerian_trail_undirected_simple/README.md)
construct trails in graphs satisfying Eulerian degree conditions; this package
adds the minimum-cost repeated traversals needed to make an arbitrary connected
weighted graph Eulerian. [`general_weighted_matching`](../../g/general_weighted_matching/README.md)
optimizes weights on an explicit graph and does not construct the odd-vertex
shortest-path metric closure.

The algorithm is described in the [NIST Dictionary of Algorithms and Data
Structures entry for the Chinese postman problem](https://xlinux.nist.gov/dads/HTML/chinesePostman.html),
which cites the matching formulation of Edmonds and Johnson. See also the
[Berkeley IEOR 269 lecture notes](https://hochbaum.ieor.berkeley.edu/files/ieor269-2010.pdf).
This package uses the algorithm description only; all code, workloads, and
bounded contracts are written independently.

See [`RIGHTS.md`](RIGHTS.md), [`workload.json`](workload.json), the
[primary oracle](../../undirected_chinese_postman_oracle.py), the
[independent verifier oracle](../../undirected_chinese_postman_verifier_oracle.py),
and the package-local [static inventory checker](../../check_undirected_chinese_postman_package.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/u/undirected_chinese_postman.c`](../../../c/u/undirected_chinese_postman.c) |
| C3 | [`c3/u/undirected_chinese_postman.c3`](../../../c3/u/undirected_chinese_postman.c3) |
| C++ | [`cpp/u/undirected_chinese_postman.cpp`](../../../cpp/u/undirected_chinese_postman.cpp) |
| Elisa | [`elisa/u/undirected_chinese_postman.elisa`](../../../elisa/u/undirected_chinese_postman.elisa) |
| Mojo | [`mojo/u/undirected_chinese_postman.mojo`](../../../mojo/u/undirected_chinese_postman.mojo) |
| Nim | [`nim/u/undirected_chinese_postman.nim`](../../../nim/u/undirected_chinese_postman.nim) |
| Odin | [`odin/u/undirected_chinese_postman.odin`](../../../odin/u/undirected_chinese_postman.odin) |
| Rust | [`rust/u/undirected_chinese_postman.rs`](../../../rust/u/undirected_chinese_postman.rs) |
| V | [`v/u/undirected_chinese_postman.v`](../../../v/u/undirected_chinese_postman.v) |
| Zig | [`zig/u/undirected_chinese_postman.zig`](../../../zig/u/undirected_chinese_postman.zig) |
