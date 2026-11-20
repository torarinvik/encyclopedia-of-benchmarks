# Aho BUILD rooted-triplet tree

This package implements the Aho–Sagiv–Szymanski–Ullman BUILD procedure for
testing rooted-triplet compatibility and, when compatible, returning the
particular tree produced by the BUILD/Aho recurrence. It does not claim that
this tree is globally least-resolved.

## Bounded contract

The ABI is `i64_array_bytes_output`. Input is
`[n,q,(a,b,c)*q]`, where `(a,b,c)` denotes rooted triplet `ab|c`. Taxa are
zero-based labels in `0..n-1`; the clustered pair is unordered, so ports
normalize it internally. Require `1<=n<=7`, `0<=q<=3*C(n,3)`, three distinct
labels per triplet, and no duplicate oriented triplets after pair
normalization. An unconstrained taxon remains part of the leaf set. The exact
frame length is `2+3q`; maximum valid and parseable frames are 317 and 318
signed-i64 words.

At each recursive leaf set `S`, build the undirected Aho graph on `S`, adding
edge `{a,b}` for every `ab|c` whose three taxa are all in `S`. If the graph is
connected and `|S|>1`, the input is incompatible. Otherwise recurse on each
connected component and attach its result below a new internal node. The
components are ordered by their smallest taxon label for stable serialization;
this ordering is only a deterministic refinement of the algorithm's
unordered children. Singletons become leaves. No unary internal nodes are
created.

For a compatible input the byte output is a sequence of signed little-endian
i64 words: `[node_count, preorder_tokens...]`. A leaf labelled `x` is token
`-(x+1)`; an internal node's token is its child count (at least two). This
prefix encoding is unambiguous. An incompatible valid input returns the
single-word payload `[0]`. Invalid input returns `-1`; null output or
insufficient capacity returns `-2` without writing. Even the one-leaf case
emits a 16-byte payload, so it requires a non-null output buffer. The largest
tree has at most `2n-1=13` nodes, giving a maximum output of 112 bytes
including the count word.

The implementation uses fixed arrays for at most 105 triplets, seven graph
vertices, 13 tree nodes, and a 13-entry traversal stack. The package reserves
8,192 bytes of workspace. The primary adjacency/BFS implementation takes
`O(nq+n^3)` bounded word operations with this direct per-recursion rebuild;
the independent DSU component formulation with path compression takes
`O(nq α(n)+n^2)`. Both use
`O(q+n^2)` fixed storage. With `n<=7` and `q<=105`, the explicit limits are
more informative than asymptotic behavior.

## Relationship to local benchmarks

`directed_perfect_phylogeny` checks laminar compatibility of binary
characters; `phylogenetic_tree_from_distance_matrix` constructs a tree from
pairwise distances; `nni_phylogeny_distance` computes a distance between
already supplied trees. This package instead decides consistency of rooted
triplet constraints and emits the BUILD/Aho tree. The Chapter 92 discussion
of galled networks is context only; its network construction is outside this
profile.

## Sources and rights

Operational method: A. V. Aho, Y. Sagiv, T. G. Szymanski, and J. D. Ullman,
“Inferring a Tree from Lowest Common Ancestors with an Application to the
Optimization of Relational Expressions,” *SIAM Journal on Computing* 10(3),
1981, pp. 405–421, [DOI 10.1137/0210030](https://doi.org/10.1137/0210030).
The chapter context is Jesper Jansson and Wing-Kin Sung, “Algorithms for
Combining Rooted Triplets into a Galled Phylogenetic Network,” *Encyclopedia
of Algorithms*, Chapter 92, [DOI
10.1007/978-1-4939-2864-4_92](https://doi.org/10.1007/978-1-4939-2864-4_92).
The paper supplies the tree consistency construction; Chapter 92 supplies the
phylogenetic-network context and cites the tree method. See [RIGHTS.md](RIGHTS.md)
for clean-room provenance. No source code, test data, prose, or examples were
copied.

## Package files

- [Primary adjacency/BFS reference](primary_oracle.py)
- [Independent union-find reference](independent_oracle.py)
- [Bounded workload](workload.json)
- [Workload review helper](verify_workload.py)
- [Static source inventory](INVENTORY.md) and [JSON inventory](INVENTORY.json)
- [Static inventory helper](check_inventory.py)
- [Chapter/method crosswalk](SOURCE_CROSSWALK.md)

## Language ports

| Language | Source |
|---|---|
| C | [`c/a/aho_build_rooted_triplet_tree.c`](../../../c/a/aho_build_rooted_triplet_tree.c) |
| C3 | [`c3/a/aho_build_rooted_triplet_tree.c3`](../../../c3/a/aho_build_rooted_triplet_tree.c3) |
| C++ | [`cpp/a/aho_build_rooted_triplet_tree.cpp`](../../../cpp/a/aho_build_rooted_triplet_tree.cpp) |
| Elisa | [`elisa/a/aho_build_rooted_triplet_tree.elisa`](../../../elisa/a/aho_build_rooted_triplet_tree.elisa) |
| Mojo | [`mojo/a/aho_build_rooted_triplet_tree.mojo`](../../../mojo/a/aho_build_rooted_triplet_tree.mojo) |
| Nim | [`nim/a/aho_build_rooted_triplet_tree.nim`](../../../nim/a/aho_build_rooted_triplet_tree.nim) |
| Odin | [`odin/a/aho_build_rooted_triplet_tree.odin`](../../../odin/a/aho_build_rooted_triplet_tree.odin) |
| Rust | [`rust/a/aho_build_rooted_triplet_tree.rs`](../../../rust/a/aho_build_rooted_triplet_tree.rs) |
| V | [`v/a/aho_build_rooted_triplet_tree.v`](../../../v/a/aho_build_rooted_triplet_tree.v) |
| Zig | [`zig/a/aho_build_rooted_triplet_tree.zig`](../../../zig/a/aho_build_rooted_triplet_tree.zig) |

The package is registered in the shared `i64_array_bytes_output` runner,
independent verifier, and catalog.
