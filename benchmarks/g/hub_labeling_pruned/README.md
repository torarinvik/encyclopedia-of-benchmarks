# Pruned hierarchical hub labeling

This package builds the canonical hierarchical hub labels for an undirected,
unweighted graph and a supplied vertex order. The order is listed from highest
rank to lowest rank. For each hub in that order, the implementation runs a
pruned breadth-first search. Before expanding a reached vertex, it queries the
labels already built and prunes the vertex when the existing estimate is no
greater than its BFS distance. Otherwise it adds the hub and distance to the
vertex's label and continues its search. Neighbor scans use increasing vertex
IDs, and output labels are sorted by hub ID.

Input is `[n,m,order_high_to_low...,u0,v0,...]`. The graph must be connected,
simple, undirected, and have `1 <= n <= 8`; every vertex pair must have a unique
shortest path. Normalized edge pairs `u<v` must be strictly lexicographically
sorted. The order must be a permutation. Each
output vertex record is a label count followed by packed hub-distance entries;
the low byte contains the hub ID and the next byte contains the distance.
Invalid input returns `-1`; null output or insufficient capacity returns
`-2` without writing. Maximum input length is 66 values and maximum output is
584 bytes.

The primary oracle implements the source's pruned BFS searches. The independent
verifier computes all-pairs shortest-path distances, then applies the canonical
definition directly: for every vertex pair it chooses the highest-ranked
vertex on its unique shortest path and adds that hub to both endpoint labels.
Input validation counts shortest paths with a cap of two from every source and
rejects a graph as soon as a pair has multiple shortest paths. BFS scans
neighbors in increasing vertex-ID order.
This profile fixes a single order and an undirected unit-length graph; it does
not implement the chapter's greedy order selection, general-labeling
approximation, or directed forward/backward variant.
The dense bounded representation uses O(n³) time for uniqueness validation
and pruned searches, and O(n²) space for adjacency and labels. The Mojo
draft has not been compiled or run.
The three-vertex path fixture and its short-output variant use the order
`[1,0,2]` and edges `(0,1),(1,2)`; their framing was corrected by static
review. The workload and references remain unexecuted.
Verifier source enumerates every simple graph on up to four vertices and
every rank order, compares the two references, and specifies output-capacity
and null-pointer cases. These checks have not been run.

Source: “Hub Labeling (2-Hop Labeling),” Daniel Delling, Andrew V. Goldberg,
and Renato F. Werneck, *Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_580`](https://doi.org/10.1007/978-1-4939-2864-4_580).
The chapter is used for the PL procedure and canonical-label definition; this
is clean-room code with no copied text, figures, or source code.

Primary oracle: [`hub_labeling_pruned_oracle.py`](../../hub_labeling_pruned_oracle.py).
Independent verifier: [`hub_labeling_pruned_verifier_oracle.py`](../../hub_labeling_pruned_verifier_oracle.py).

| Language | Port |
|---|---|
| C | `c/g/hub_labeling_pruned.c` |
| C3 | `c3/g/hub_labeling_pruned.c3` |
| C++ | `cpp/g/hub_labeling_pruned.cpp` |
| Elisa | `elisa/g/hub_labeling_pruned.elisa` |
| Mojo | [mojo/g/hub_labeling_pruned.mojo](../../../mojo/g/hub_labeling_pruned.mojo) (uncompiled draft) |
| Nim | `nim/g/hub_labeling_pruned.nim` |
| Odin | `odin/g/hub_labeling_pruned.odin` |
| Rust | `rust/g/hub_labeling_pruned.rs` |
| V | `v/g/hub_labeling_pruned.v` |
| Zig | `zig/g/hub_labeling_pruned.zig` |
