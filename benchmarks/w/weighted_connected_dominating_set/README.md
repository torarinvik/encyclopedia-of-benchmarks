# Weighted connected dominating set

This package solves the minimum weighted connected dominating set objective
exactly on small undirected graphs. A selected vertex set must dominate every
vertex, and the subgraph induced by selected vertices must be connected. The
implementation enumerates all nonempty subsets and chooses minimum total
positive vertex weight, with the numerically smallest bit mask breaking equal
costs.

Input is `[n,adjacency_mask[n],weight[n]]`, with `1 <= n <= 16`, simple
undirected adjacency, and weights in `[1,1000]`. Output is `[minimum_cost,
selected_vertex_mask]`; `[-1,0]` means no connected dominating set exists (for
example, a disconnected graph). Both fields are signed little-endian i64.
Invalid input returns `-1`; null output or insufficient capacity returns
`-2` without writing.

The chapter focuses on a distributed approximation algorithm with clustering
and connector phases. This profile measures the exact weighted connected
dominating set objective
on a bounded graph; it does not claim to reproduce that distributed protocol,
its approximation ratio, or its communication complexity.

Source: “Weighted Connected Dominating Set,” *Encyclopedia of Algorithms*,
DOI [`10.1007/978-1-4939-2864-4_476`](https://doi.org/10.1007/978-1-4939-2864-4_476).
The ports are clean-room; no chapter prose or source code was copied.

## Ports

| Language | Port |
|---|---|
| C | `c/w/weighted_connected_dominating_set.c` |
| C3 | `c3/w/weighted_connected_dominating_set.c3` |
| C++ | `cpp/w/weighted_connected_dominating_set.cpp` |
| Elisa | `elisa/w/weighted_connected_dominating_set.elisa` |
| Nim | `nim/w/weighted_connected_dominating_set.nim` |
| Odin | `odin/w/weighted_connected_dominating_set.odin` |
| Rust | `rust/w/weighted_connected_dominating_set.rs` |
| V | `v/w/weighted_connected_dominating_set.v` |
| Zig | `zig/w/weighted_connected_dominating_set.zig` |

Primary oracle: `benchmarks/weighted_connected_dominating_set_oracle.py`.
Independent verifier oracle: `benchmarks/weighted_connected_dominating_set_verifier_oracle.py`.
