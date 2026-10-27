# Phylogenetic Tree from a Distance Matrix

This bounded profile reconstructs the unique minimum-node tree realizing an
additive distance matrix, or returns a null tree for a well-formed matrix that
is not additive. It is attributed to “Phylogenetic Tree Construction from a
Distance Matrix,” Jesper Jansson, *Encyclopedia of Algorithms*, DOI
10.1007/978-1-4939-2864-4_292.

## Contract

The ABI is `i64_array_bytes_output`. Input is `[n,D[0,0],...,D[n-1,n-1]]`,
with `2<=n<=6`, zero diagonal, symmetric positive integer off-diagonal
distances in `[1,32]`. Malformed matrices return `-1`.

The algorithm is the recursive additive-tree reduction, executed as its
leaf-insertion unwind. It starts from the two-leaf tree and inserts leaves in
increasing label order. For leaf `v`, it computes twice the limb length as
`min(D[i,v]+D[j,v]-D[i,j])`, selecting the lexicographically first pair
`i<j` whose limb-adjusted distances place the attachment point on path `i..j`.
Along that unique path, an attachment exactly at an existing vertex uses that
vertex; an interior attachment splits that edge. A zero-length limb labels
the attachment vertex directly, yielding the minimum-node representation.
The profile verifies every reconstructed pair distance before returning the
tree; if reconstruction fails or any pair differs, it returns a null tree.

A non-null tree is encoded as `[edge_count,(side_mask,weight2)*]`. Each edge's
`side_mask` is the set of taxon IDs on the component containing taxon 0, and
`weight2` is twice the edge length. Edge records are sorted by mask, then
weight. Output uses at most 9 edges (152 bytes). A well-formed non-additive
matrix succeeds with zero output bytes, representing the required null tree.
A null or undersized output buffer for an additive matrix returns `-2` without
writing output.

The primary oracle performs prefix insertion using an edge list. The
independent verifier applies the recursive leaf-removal recurrence with an
adjacency-map tree. Both preserve exact half-integral branch lengths by
storing doubled weights. The profile excludes approximate/non-additive
phylogeny reconstruction methods such as Neighbor Joining.

## Files

Nine ports live under `c/p`, `cpp/p`, `rust/p`, `c3/p`, `nim/p`, `odin/p`,
`elisa/p`, `v/p`, and `zig/p`, alongside the workload and both Python oracles.
