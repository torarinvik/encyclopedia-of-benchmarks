# Fixed-edge shortest path in a Monge DAG

This benchmark finds the minimum-cost path from vertex `0` to vertex `N` using
exactly `D` edges. The graph is implicit and complete in the forward direction:
an edge exists from `i` to `j` exactly when `i < j`. Its upper-triangular edge
cost matrix satisfies the Monge quadrangle inequality. The exact-edge dynamic
program has transition

`dp[d][j] = min(dp[d-1][i] + c(i,j))` over `i < j`.

For every edge-count layer, Monge ordering makes the minimizing predecessor
indices nondecreasing as the target increases. The ports use monotone
divide-and-conquer minima to compute the row minima, rather than scanning each
possible predecessor. They retain only the previous and current DP layers.

## Contract

The `i64_array_scalar` symbol is `monge_dag_fixed_edge_shortest_path(input,
length) -> i64`. Input is `[N,D, c(0,1),c(0,2),...,c(0,N), c(1,2),...,c(N-1,N)]`.
There are `N+1` vertices labeled `0..N`, `1 <= N <= 32`, and `1 <= D <= N`.
Edge costs are integers in `[0,1,000,000]`, stored in row-major upper-triangle
order by source and then destination. The array must contain exactly
`2 + N*(N+1)/2` words. The ports validate the local Monge inequality for every
fully present adjacent quadrangle. Malformed input or a non-Monge cost matrix
returns `-1`; every valid frame has a path of exactly `D` edges. The maximum
valid result is 32,000,000.

The primary oracle computes each layer with monotone divide-and-conquer row
minima. The independent oracle scans every eligible predecessor in each layer.
The workload includes a squared-gap Monge matrix at every possible edge count,
a tie between distinct optimal paths, zero costs, non-Monge data, and malformed
frames.

## Distinction and sources

[`fixed_length_walk_minplus`](../fixed_length_walk_minplus/README.md) accepts
an explicit graph and uses min-plus matrix powers for arbitrary exact-length
walk queries. This package instead uses an implicit complete forward DAG and
exploits the Monge structure to compute one source-to-sink exact-edge optimum.
[`min_plus_convolution_convex_arbitrary`](../min_plus_convolution_convex_arbitrary/README.md)
has a convolution-specific transition matrix, while
[`smawk_row_minima`](../../s/smawk_row_minima/README.md) solves a general
explicit matrix row-minimum problem without this shortest-path recurrence.

The algorithm topic is described by Bein, Larmore, and Park in “The d-Edge
Shortest-Path Problem for a Monge Graph,” [Sandia report SAND-92-1724CDE93](https://www.osti.gov/servlets/purl/10146169).
Nyaan's [Monge d-edge path enumeration](https://nyaannyaan.github.io/library/dp/monge-d-edge-shortest-path-enumerate.hpp.html)
is an additional implementation-idea reference. Only algorithm descriptions
were used; all contract text, ports, fixtures, and references are independently
written. See [`RIGHTS.md`](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [`c/m/monge_dag_fixed_edge_shortest_path.c`](../../../c/m/monge_dag_fixed_edge_shortest_path.c) |
| C3 | [`c3/m/monge_dag_fixed_edge_shortest_path.c3`](../../../c3/m/monge_dag_fixed_edge_shortest_path.c3) |
| C++ | [`cpp/m/monge_dag_fixed_edge_shortest_path.cpp`](../../../cpp/m/monge_dag_fixed_edge_shortest_path.cpp) |
| Elisa | [`elisa/m/monge_dag_fixed_edge_shortest_path.elisa`](../../../elisa/m/monge_dag_fixed_edge_shortest_path.elisa) |
| Mojo | [`mojo/m/monge_dag_fixed_edge_shortest_path.mojo`](../../../mojo/m/monge_dag_fixed_edge_shortest_path.mojo) |
| Nim | [`nim/m/monge_dag_fixed_edge_shortest_path.nim`](../../../nim/m/monge_dag_fixed_edge_shortest_path.nim) |
| Odin | [`odin/m/monge_dag_fixed_edge_shortest_path.odin`](../../../odin/m/monge_dag_fixed_edge_shortest_path.odin) |
| Rust | [`rust/m/monge_dag_fixed_edge_shortest_path.rs`](../../../rust/m/monge_dag_fixed_edge_shortest_path.rs) |
| V | [`v/m/monge_dag_fixed_edge_shortest_path.v`](../../../v/m/monge_dag_fixed_edge_shortest_path.v) |
| Zig | [`zig/m/monge_dag_fixed_edge_shortest_path.zig`](../../../zig/m/monge_dag_fixed_edge_shortest_path.zig) |

The `i64_array_scalar` runner and verifier are wired to the symbol
`monge_dag_fixed_edge_shortest_path`.

The bounded workspace metadata is 16,384 bytes. This covers the fixed
33-by-33 cost table, two DP rows, and the explicit monotone-minima frame stack.
