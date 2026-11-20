# Hash-free Weisfeiler–Lehman color refinement

This profile computes the stable one-dimensional Weisfeiler–Lehman (1-WL)
coloring of one small, unlabeled, simple undirected graph. It measures the
canonical color-refinement core associated with NetworkX's
[`weisfeiler_lehman_graph_hash`](https://networkx.org/documentation/stable/reference/algorithms/generated/networkx.algorithms.graph_hashing.weisfeiler_lehman_graph_hash.html),
but returns color IDs instead of a cryptographic digest. The result is not a
complete graph-isomorphism test: distinct graphs can have the same stable
coloring.

## Contract

The `i64_array_scalar` input is `[N,adjacency_mask_0,...,adjacency_mask_(N-1)]`
for `0<=N<=8`. Every mask fits in N bits; diagonal bits are zero and the
adjacency relation is symmetric. The output is the stable color of each
vertex, packed as `sum(color[v]*9^v)`, so vertex 0 occupies the least
significant base-9 digit. Invalid input returns `-1`; every valid result is
nonnegative. Empty input graphs return zero.

For an unlabeled graph, initialize each vertex with its degree. A refinement
round gives each vertex the signature consisting of its
current color and its sorted multiset of neighbor colors. Sort distinct
signatures lexicographically and assign their ascending ranks. Stop after the
first round that does not increase the number of color classes. Since each
signature retains the old color, classes never merge; an unchanged class count
means the partition has stabilized. Canonical ranks make the colors
deterministic and independent of hash collisions.

The primary oracle sorts explicit signature tuples. The independent oracle
keeps ordered partition blocks and splits each block by neighbor-color
multisets. Both produce the same canonical stable coloring through different
representations. The largest packed color vector is below `9^8`, and the
maximum valid and parseable input lengths are 9 and 10 words.

## Sources and provenance

NetworkX's official [`weisfeiler_lehman_graph_hash` documentation](https://networkx.org/documentation/stable/reference/algorithms/generated/networkx.algorithms.graph_hashing.weisfeiler_lehman_graph_hash.html)
describes degree initialization for unlabeled graphs and iterative neighborhood
aggregation. It cites Shervashidze et al., [“Weisfeiler-Lehman Graph Kernels,”
JMLR 12 (2011)](https://jmlr.org/papers/v12/shervashidze11a.html), which defines
1-dimensional label refinement and canonical compression. The NetworkX
repository's README/topics were used for source discovery; no implementation
code or documentation prose was copied. This package implements only the
mathematical refinement, not the NetworkX digest format. See [RIGHTS.md](RIGHTS.md).

## Workload and source review

[`workload.json`](workload.json) includes empty, regular, path, and star graphs,
an eight-vertex refinement case, and malformed masks/framing.
[`primary_oracle.py`](primary_oracle.py) and
[`independent_oracle.py`](independent_oracle.py) provide independent references.
[`verify_weisfeiler_lehman_color_refinement_package.py`](verify_weisfeiler_lehman_color_refinement_package.py)
contains static workload, provenance, and ten-port inventory checks. No
programs or checks have been run.

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/w/weisfeiler_lehman_color_refinement.c`](../../../c/w/weisfeiler_lehman_color_refinement.c) |
| C3 | [`c3/w/weisfeiler_lehman_color_refinement.c3`](../../../c3/w/weisfeiler_lehman_color_refinement.c3) |
| C++ | [`cpp/w/weisfeiler_lehman_color_refinement.cpp`](../../../cpp/w/weisfeiler_lehman_color_refinement.cpp) |
| Elisa | [`elisa/w/weisfeiler_lehman_color_refinement.elisa`](../../../elisa/w/weisfeiler_lehman_color_refinement.elisa) |
| Mojo | [`mojo/w/weisfeiler_lehman_color_refinement.mojo`](../../../mojo/w/weisfeiler_lehman_color_refinement.mojo) |
| Nim | [`nim/w/weisfeiler_lehman_color_refinement.nim`](../../../nim/w/weisfeiler_lehman_color_refinement.nim) |
| Odin | [`odin/w/weisfeiler_lehman_color_refinement.odin`](../../../odin/w/weisfeiler_lehman_color_refinement.odin) |
| Rust | [`rust/w/weisfeiler_lehman_color_refinement.rs`](../../../rust/w/weisfeiler_lehman_color_refinement.rs) |
| V | [`v/w/weisfeiler_lehman_color_refinement.v`](../../../v/w/weisfeiler_lehman_color_refinement.v) |
| Zig | [`zig/w/weisfeiler_lehman_color_refinement.zig`](../../../zig/w/weisfeiler_lehman_color_refinement.zig) |
