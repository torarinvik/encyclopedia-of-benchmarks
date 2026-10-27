# Greedy-order hierarchical hub labeling

This profile implements the chapter's greedy vertex-order selection for
hierarchical hub labels (DOI 10.1007/978-1-4939-2864-4_580). It starts with
all ordered source/target pairs uncovered, including self-pairs. In each round
it chooses the vertex lying on the greatest number of still-uncovered unique
shortest paths; ties go to the lowest vertex ID. It then marks every path
through that vertex covered and repeats. This is equivalent to removing that
vertex and its descendants from each source's shortest-path tree, as described
in the chapter.

The input is `[n,m,u0,v0,...]`, with `1<=n<=8`, simple undirected unit edges
`u<v`, and strictly lexicographically ordered edge pairs. The graph must be
connected and every vertex pair must have a unique shortest path. Neighbor
scans and all ties are resolved by ascending vertex ID. The resulting
high-to-low order is used to construct the canonical hierarchical labels: for
each unordered vertex pair, select the highest-ranked vertex on its unique
shortest path and add that hub with the appropriate distance to both endpoint
labels. The output includes the chosen order, then each vertex's hub count and
packed `(hub ID, distance)` entries sorted by hub ID.

ABI: `i64_array_bytes_output`, symbol `hub_labeling_greedy_order`. Invalid
input returns `-1`; null output or capacity below the actual staged result
returns `-2` without writing. The maximum input is 58 i64 words. The maximum
output is 81 i64 words (648 bytes): one header, up to eight order entries, and
up to eight labels per each of eight vertices. The bounded serial simulation
does not claim the chapter's large-graph running-time bounds.

This is distinct from [`hub_labeling_pruned`](../hub_labeling_pruned/README.md),
which takes a supplied order and constructs labels with pruned BFS. Here the
order itself is computed by the chapter's uncovered-path greedy rule; the
labels are then formed from the canonical definition. The primary oracle uses
rooted shortest-path trees and descendant removal. The independent verifier
enumerates bounded simple paths, verifies uniqueness, and derives coverage and
labels directly from those paths.

Source: Delling, Goldberg, and Werneck, “Hub Labeling (2-Hop Labeling),”
*Encyclopedia of Algorithms*, DOI 10.1007/978-1-4939-2864-4_580. See
[`RIGHTS.md`](RIGHTS.md) for attribution and source scope.

| Language | Port |
|---|---|
| C | `c/h/hub_labeling_greedy_order.c` |
| C3 | `c3/h/hub_labeling_greedy_order.c3` |
| C++ | `cpp/h/hub_labeling_greedy_order.cpp` |
| Elisa | `elisa/h/hub_labeling_greedy_order.elisa` |
| Nim | `nim/h/hub_labeling_greedy_order.nim` |
| Odin | `odin/h/hub_labeling_greedy_order.odin` |
| Rust | `rust/h/hub_labeling_greedy_order.rs` |
| V | `v/h/hub_labeling_greedy_order.v` |
| Zig | `zig/h/hub_labeling_greedy_order.zig` |
