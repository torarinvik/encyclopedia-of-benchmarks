# Nearest-neighbor-interchange distance for phylogenies

This package computes the exact NNI distance for two unrooted binary
phylogenies with the same labeled leaves. Each tree is represented by all of
its `2n-3` edge bipartitions. A mask stores the side that excludes leaf 0;
pendant and internal edges are both included. The result is the minimum number
of NNI operations, where one operation exchanges two incident subtrees across
an internal edge.

Input is `[n, splits_A..., splits_B...]`, with `3 <= n <= 7`. Every split set
must contain all pendant edges and a compatible set of `n-3` internal edges.
Output is one little-endian signed 64-bit distance. Invalid input returns
`-1`; null output or capacity below 8 bytes returns `-2` without writing.
Maximum input length is 23 values.

The bounded implementation enumerates the finite state space by inserting
leaves into each edge of smaller trees, then finds a shortest path in the NNI
graph. At seven leaves there are at most 945 labeled unrooted binary
topologies. This is an exact small-instance profile of the distance defined
in the chapter; it is not the chapter's polynomial approximation algorithm.

The primary oracle searches the canonical split-state graph. The independent
verifier reconstructs adjacency lists for each tree, applies local subtree
exchanges, and searches those generated neighbors.

Source: “Nearest Neighbor Interchange and Related Distances,” Bhaskar
DasGupta, Xin He, Ming Li, John Tromp, and Louxin Zhang, *Encyclopedia of
Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_256`](https://doi.org/10.1007/978-1-4939-2864-4_256).
The chapter is used for the operation and distance definitions; this is
clean-room code with no copied text, figures, or source code.

Primary oracle: [`nni_phylogeny_distance_oracle.py`](../../nni_phylogeny_distance_oracle.py).
Independent verifier: [`nni_phylogeny_distance_verifier_oracle.py`](../../nni_phylogeny_distance_verifier_oracle.py).

| Language | Port |
|---|---|
| C | `c/n/nni_phylogeny_distance.c` |
| C3 | `c3/n/nni_phylogeny_distance.c3` |
| C++ | `cpp/n/nni_phylogeny_distance.cpp` |
| Elisa | `elisa/n/nni_phylogeny_distance.elisa` |
| Nim | `nim/n/nni_phylogeny_distance.nim` |
| Odin | `odin/n/nni_phylogeny_distance.odin` |
| Rust | `rust/n/nni_phylogeny_distance.rs` |
| V | `v/n/nni_phylogeny_distance.v` |
| Zig | `zig/n/nni_phylogeny_distance.zig` |
