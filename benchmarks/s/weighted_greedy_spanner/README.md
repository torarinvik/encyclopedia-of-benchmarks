# Weighted graph greedy spanner

This package implements Algorithm I from the chapter: process undirected
weighted edges in increasing weight order and add an edge exactly when the
current spanner's shortest path between its endpoints exceeds
`(2k - 1) * edge_weight`. Equal weights use lexicographic `(u, v)` order.
Weights are positive integers and vertices use zero-based IDs.

The bounded input is `[n, m, k, (u, v, weight)...]`, with `2 <= n <= 8`,
`0 <= m <= 28`, `1 <= k <= 3`, and weights in `1..=32`. Each undirected edge
must be unique and have `u < v`. Output is one byte per supplied edge, in
input order (`1` means retained). Malformed input returns `-1`; a null output
or insufficient capacity returns `-2` without writes. The profile caps output
at 28 bytes and uses Dijkstra for each bounded insertion decision; it makes no
claim to the source's asymptotic runtime.

The package oracle follows the greedy edge sequence with Dijkstra. The
independent verifier recomputes current-spanner distances with Floyd–Warshall.

Source: Surender Baswana and Sandeep Sen, “Simple Algorithms for Spanners in
Weighted Graphs,” *Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_10`](https://doi.org/10.1007/978-1-4939-2864-4_10).
The separate [Euclidean t-spanner](../euclidean_t_spanner/README.md) profile
has a geometric point-set input and is not an algorithm match for this general
weighted-graph procedure. This clean-room package contains no copied book
text, figures, or code; see [RIGHTS.md](RIGHTS.md).

## Workload and ports

The [workload](workload.json) covers empty, disconnected, tied-weight,
shortcut, `k=1`, maximum-output, malformed, null, and capacity cases.

| Language | Port |
| --- | --- |
| C | [`c/s/weighted_greedy_spanner.c`](../../../c/s/weighted_greedy_spanner.c) |
| C3 | [`c3/s/weighted_greedy_spanner.c3`](../../../c3/s/weighted_greedy_spanner.c3) |
| C++ | [`cpp/s/weighted_greedy_spanner.cpp`](../../../cpp/s/weighted_greedy_spanner.cpp) |
| Elisa | [`elisa/s/weighted_greedy_spanner.elisa`](../../../elisa/s/weighted_greedy_spanner.elisa) |
| Nim | [`nim/s/weighted_greedy_spanner.nim`](../../../nim/s/weighted_greedy_spanner.nim) |
| Odin | [`odin/s/weighted_greedy_spanner.odin`](../../../odin/s/weighted_greedy_spanner.odin) |
| Rust | [`rust/s/weighted_greedy_spanner.rs`](../../../rust/s/weighted_greedy_spanner.rs) |
| V | [`v/s/weighted_greedy_spanner.v`](../../../v/s/weighted_greedy_spanner.v) |
| Zig | [`zig/s/weighted_greedy_spanner.zig`](../../../zig/s/weighted_greedy_spanner.zig) |
