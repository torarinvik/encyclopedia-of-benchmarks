# Christofides' metric TSP approximation

This clean-room profile implements Algorithm 2 from the Encyclopedia's
“Metric TSP” chapter: compute an MST, find a minimum-weight perfect matching
on its odd-degree vertices, traverse the resulting Eulerian multigraph, and
shortcut repeated vertices. This is the chapter's 3/2-approximation for
complete metrics.

## Contract

Input is `[n, row-major n-by-n distance matrix]`, with `1 <= n <= 8`, integral
distances in `[0,10000]`, zero diagonal, symmetry, and the triangle inequality.
The MST uses Kruskal order `(weight,u,v)`. Among equal-cost perfect matchings,
the lexicographically smallest sorted pair sequence is selected. Euler's
algorithm starts at vertex 0 and repeatedly takes the least-ID available
neighbor; shortcutting keeps each vertex's first occurrence. The output is
`[tour_cost, vertex_0, ..., vertex_(n-1), 0]` as little-endian signed i64
values, with each vertex listed once before returning to zero. Output capacity
is `8*(n+2)` bytes, at most 80. Invalid input returns `-1`; null output or
short capacity returns `-2` after input validation. Errors do not write.

The bounded odd-set matching uses exact subset dynamic programming; it is a
small-instance implementation of the source's minimum perfect matching step,
not a production cubic-time general matching implementation. Input still
represents a metric, so shortcutting preserves feasibility and the
Christofides 3/2 analysis.

## Source scope and rights

The algorithm is from “Metric TSP,” DOI
[`10.1007/978-1-4939-2864-4_230`](https://doi.org/10.1007/978-1-4939-2864-4_230),
Algorithm 2. The chapter also presents tree doubling, which is covered by the
separate [`metric_tsp_tree_doubling`](../metric_tsp_tree_doubling/README.md)
profile. This package adds the odd-degree perfect-matching step and Eulerian
shortcut construction. The book is used as an algorithm reference only; no
book prose, figures, or code are copied, and its citation does not grant
redistribution rights.

The primary and independent verifier oracles are
[`metric_tsp_christofides_oracle.py`](../../metric_tsp_christofides_oracle.py)
and
[`metric_tsp_christofides_verifier_oracle.py`](../../metric_tsp_christofides_verifier_oracle.py).

## Ports

| Language | Port |
|---|---|
| C | `c/m/metric_tsp_christofides.c` |
| C3 | `c3/m/metric_tsp_christofides.c3` |
| C++ | `cpp/m/metric_tsp_christofides.cpp` |
| Elisa | `elisa/m/metric_tsp_christofides.elisa` |
| Nim | `nim/m/metric_tsp_christofides.nim` |
| Odin | `odin/m/metric_tsp_christofides.odin` |
| Rust | `rust/m/metric_tsp_christofides.rs` |
| V | `v/m/metric_tsp_christofides.v` |
| Zig | `zig/m/metric_tsp_christofides.zig` |
